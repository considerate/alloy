{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE OverloadedStrings #-}

import Control.Monad
import Data.Bifunctor
import Data.Map qualified as M
import Eval
import Expr
import Lib
import Parse
import Prettyprinter
import Print
import Test.Tasty
import Test.Tasty.Focus
import Test.Tasty.HUnit
import Text.Megaparsec qualified as MP

main :: IO ()
main =
  defaultMain $
    testGroup
      "alloy-test"
      [ evalTests,
        testSyntax
      ]

assertParse :: String -> IO (Either String Value)
assertParse str = do
  case MP.parse pToplevel "" str of
    Left err -> assertFailure $ MP.errorBundlePretty err
    Right r -> pure $ first show (evalInfo r)

testSyntax :: TestTree
testSyntax = testCase "syntax.ayy" $ do
  f <- readFile "syntax.ayy"
  assertParse f >>= \case
    Left err -> assertFailure err
    Right val -> assertFailure . show $ ppVal val

evalTests :: TestTree
evalTests =
  withFocus . testGroup "eval" $
    fmap
      (uncurry is9)
      [ ("const", "9"),
        ("add", "4+5"),
        ("mul", "3*3"),
        ("sub", "13-4"),
        ("precedence", "3 * 5 - 6"),
        ("precedence 2", "3 * 13 - 5 * 6"),
        ("associativity", "15 - 5 - 1"),
        ("id", "(x: x) 9"),
        ("fst", "(x: y: x) 9 11"),
        ("snd", "(x: y: y) 11 9"),
        ("simple attribute set", "{foo: 9}.foo"),
        ("simple let binding", "let x = 9; in x"),
        ( "let with local reference",
          "let y = 9; \
          \    x = y; \
          \ in x"
        ),
        ( "nested attrs",
          "{foo: {bar: 9}}.foo.bar"
        ),
        ( "let binding with nested attrs",
          "let attrs = {foo: {bar: 9}}; \
          \ in attrs.foo.bar"
        ),
        ("reference in attr binding", "(x: {a: x}.a) 9"),
        ( "not sure what to call it but it used to fail",
          "let id = x: x; \
          \    x = 9; \
          \ in id x"
        ),
        ( "id id id id id",
          "let id = x: x; \
          \    x = 9; \
          \ in id id id id x"
        ),
        ( "scoping test",
          "(id: x: (id id) (id x)) (x: x) 9"
        ),
        ( "laziness test",
          "let diverge = (x: x x) (x: x x); in 9"
        ),
        ( "lazy inheritance test",
          "let diverge = (x: x x) (x: x x); \
          \    x = 9;                       \
          \ in { inherit diverge,           \
          \      inherit x                  \
          \    }.x"
        ),
        ("simple builtin", "builtins.nine"),
        ( "laziness ignores undefined",
          "let x = builtins.undefined; y = builtins.nine; in y"
        ),
        ( "fix",
          "let attr = (builtins.fix) (self: { \
          \      three: 3, \
          \      nine: self.three * self.three}); \
          \ in attr.nine"
        ),
        ( "line comments",
          unlines ["let a = 9; # comment", "in a"]
        )
      ]

is9 :: String -> String -> TestTree
is9 name prog = assertEval name prog (Fix $ VInt 9)

valueCompare :: Value -> Value -> Either (Doc ann) ()
valueCompare (Fix (VInt na)) (Fix (VInt nb)) | na == nb = pure ()
valueCompare (Fix (VAttr na)) (Fix (VAttr nb)) | M.keys na == M.keys nb = zipWithM_ valueCompare (M.elems na) (M.elems nb)
valueCompare a b = Left $ hsep ["mismatch between", ppVal a, "and", ppVal b]

assertEval :: String -> String -> Value -> TestTree
assertEval name program expect =
  testCase name $
    assertParse program >>= \case
      Left err -> assertFailure err
      Right got -> either (assertFailure . show) (const $ pure ()) $ valueCompare expect got

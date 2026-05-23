{-# LANGUAGE OverloadedStrings #-}

import Data.List (intercalate)
import Data.Maybe (fromMaybe)
import Data.Monoid (mappend)
import Hakyll

sectionContext :: Context String
sectionContext =
    listField "overview" defaultContext (loadAll "posts/01-overview/*") `mappend`
    listField "aws-services" defaultContext (loadAll "posts/02-aws-services/*")

pageContext :: Context String
pageContext = sectionContext `mappend` defaultContext

stripHtml :: String -> String
stripHtml = unwords . words . go False
  where
    go _ [] = []
    go inTag (c:cs)
        | c == '<' = go True cs
        | c == '>' = go False cs
        | inTag = go True cs
        | otherwise = c : go False cs

buildSearchIndex :: Compiler (Item String)
buildSearchIndex = do
    indexedItems <- loadAllSnapshots "posts/**" "content"
    homeItems <- loadAllSnapshots "index.html" "content"
    let searchItems = indexedItems ++ homeItems
    entries <- mapM toSearchEntry searchItems
    makeItem $ "window.DOC_SEARCH_INDEX = [" ++ intercalate "," (map toJavascriptObject entries) ++ "];"
  where
    toSearchEntry :: Item String -> Compiler (String, String, String, String)
    toSearchEntry item = do
        let identifier = itemIdentifier item
        title <- fromMaybe "Untitled" <$> getMetadataField identifier "title"
        route <- getRoute identifier
        let url = maybe ("/" ++ toFilePath identifier) (('/' :) . toUrl) route
            content = stripHtml (itemBody item)
            summary = take 180 content
        pure (title, summary, url, content)

    toJavascriptObject :: (String, String, String, String) -> String
    toJavascriptObject (title, summary, url, content) =
        "{title:" ++ show title ++
        ",summary:" ++ show summary ++
        ",url:" ++ show url ++
        ",content:" ++ show content ++
        "}"

main :: IO ()
main = hakyll $ do
    create ["search-index.js"] $ do
        route idRoute
        compile buildSearchIndex

    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "posts/01-overview/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    defaultContext
            >>= loadAndApplyTemplate "templates/default.html" pageContext
            >>= relativizeUrls

    match "posts/02-aws-services/*" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= saveSnapshot "content"
            >>= loadAndApplyTemplate "templates/post.html"    defaultContext
            >>= loadAndApplyTemplate "templates/default.html" pageContext
            >>= relativizeUrls

    match "index.html" $ do
        route idRoute
        compile $ do
            let indexCtx = pageContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= saveSnapshot "content"
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

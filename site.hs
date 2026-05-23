--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.List (intercalate)
import           Data.Maybe (fromMaybe)
import           Data.Monoid (mappend)
import           Hakyll


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match "images/*" $ do
        route   idRoute
        compile copyFileCompiler

    match "css/*" $ do
        route   idRoute
        compile compressCssCompiler

    match "js/*" $ do
        route   idRoute
        compile copyFileCompiler

    create ["search-index.js"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            pages <- loadAll (fromList ["about.rst", "contact.markdown"])

            pageEntries <- mapM searchEntryFromItem pages
            postEntries <- mapM searchEntryFromItem posts

            let searchEntries =
                    [ searchEntry "Home" "/" "Landing page"
                    , searchEntry "Archives" "/archive.html" "Browse all posts"
                    ]
                    ++ pageEntries
                    ++ postEntries

            makeItem ("window.DOC_SEARCH_INDEX = [" ++ intercalate "," searchEntries ++ "];\n")

    match (fromList ["about.rst", "contact.markdown"]) $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    match "posts/**" $ do
        route $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/post.html"    postCtx
            >>= loadAndApplyTemplate "templates/default.html" postCtx
            >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls


    match "index.html" $ do
        route idRoute
        compile $ do
            posts <- loadAll "posts/**" -- [Item String]
            let indexCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    defaultContext

            getResourceBody
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/default.html" indexCtx
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler


--------------------------------------------------------------------------------
searchEntryFromItem :: Item String -> Compiler String
searchEntryFromItem item = do
    title <- itemTitle item
    let summary = title
        url = itemUrl item
    pure (searchEntry title url summary)


searchEntry :: String -> String -> String -> String
searchEntry title url summary =
    "{\"title\":" ++ show title ++ ",\"summary\":" ++ show summary ++ ",\"url\":" ++ show url ++ "}"


itemTitle :: Item String -> Compiler String
itemTitle item = do
    metadataTitle <- getMetadataField (itemIdentifier item) "title"
    pure (fromMaybe (fallbackTitle $ itemIdentifier item) metadataTitle)


itemUrl :: Item String -> String
itemUrl item =
    case toFilePath (itemIdentifier item) of
        "index.html" -> "/"
        filePath -> '/' : replaceExtensionWithHtml filePath


fallbackTitle :: Identifier -> String
fallbackTitle = takeBaseName . toFilePath


replaceExtensionWithHtml :: FilePath -> FilePath
replaceExtensionWithHtml filePath = dropExtension filePath ++ "html"


takeBaseName :: FilePath -> String
takeBaseName = reverse . takeWhile (/= '/') . reverse . dropExtension


dropExtension :: FilePath -> FilePath
dropExtension filePath = case break (== '.') (reverse filePath) of
    (reversedBase, []) -> filePath
    (reversedBase, _:_) -> reverse reversedBase


postCtx :: Context String
postCtx =
    defaultContext

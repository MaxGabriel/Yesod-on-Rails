{-# LANGUAGE QuasiQuotes #-}
module Handler.User where


import Import
import qualified Data.Text as T
-- import App.Passwords
import OpenSSL.Random
import Data.Maybe
import Data.Text.Encoding
import OpenSSL.Random
import Data.Digest.BCrypt
import Data.ByteString

data UserForm = UserForm
    { username :: Text
    , email :: Text
    , password :: Text
    }
  deriving Show

passwordConfirmField :: Field Handler Text
passwordConfirmField = Field
    { fieldParse = \rawVals _fileVals ->
        case rawVals of
            [a, b]
                | a == b && (T.length(a) > 5) -> return $ Right $ Just a
                | (T.length(a) <= 5) -> return $ Left "Password must be more than 5 characters"
                | otherwise -> return $ Left "Passwords don't match"
            [] -> return $ Right Nothing
            _ -> return $ Left "You must enter two values"
    , fieldView = \idAttr nameAttr otherAttrs eResult isReq ->
        [whamlet|
            <input id=#{idAttr} name=#{nameAttr} *{otherAttrs} type=password>
            <label class="control-label" for=#{idAttr}-confirm>Confirmation</label>
            <input id=#{idAttr}-confirm name=#{nameAttr} *{otherAttrs} type=password>
        |]
    , fieldEnctype = UrlEncoded
    }

userForm :: Maybe UserForm -> AForm Handler UserForm
userForm mUser = UserForm
    <$> areq usernameField "User" (username <$> mUser)
    <*> areq emailField "Email" (email <$> mUser)
    <*> areq passwordConfirmField "Password" Nothing
    where
        usernameField = checkBool (\s -> T.length(s) < 50) ("Username must be less than 50 characters long" :: Text) textField

getUserR :: Handler Html
getUserR = do
    (widget, enctype) <- generateFormPost $ renderBootstrap (userForm Nothing)
    defaultLayout $ do
        $(widgetFile "signup")

hashPassword :: Text -> ByteString -> Text
hashPassword plaintext seed =
    let bytePlainText = encodeUtf8 plaintext
        salt = fromJust $ genSalt 10 seed -- Not sure why genSalt would fail, so just letting it error if so.
        byteHash = bcrypt bytePlainText salt
    in decodeUtf8 byteHash

postUserR :: Handler Html
postUserR = do
    ((res, widget), enctype) <- runFormPost $ renderBootstrap (userForm Nothing)
    seed <- liftIO $ randBytes 16
    case res of 
        FormSuccess user -> let x = hashPassword (password user) seed
                            in defaultLayout [whamlet|#{x}|]
        _                -> defaultLayout $(widgetFile "signup")



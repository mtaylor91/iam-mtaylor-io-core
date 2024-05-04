{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
module IAM.UserIdentifier
  ( module IAM.UserIdentifier
  ) where

import Data.Aeson
import Data.Aeson.TH
import Data.Text
import Data.Text.Encoding
import Data.UUID
import Servant
import Text.Email.Validate
import Text.Read (readMaybe)


newtype UserId = UserUUID { unUserId :: UUID } deriving (Eq, Show)

$(deriveJSON defaultOptions { unwrapUnaryRecords = True } ''UserId)

instance Ord UserId where
  compare (UserUUID a) (UserUUID b) = compare a b


data UserIdentifier = UserIdentifier
  { unUserIdentifierId :: !(Maybe UserId)
  , unUserIdentifierName :: !(Maybe Text)
  , unUserIdentifierEmail :: !(Maybe Text)
  } deriving (Eq, Show)

instance FromHttpApiData UserIdentifier where
  parseUrlPiece s = case readMaybe $ unpack s of
    Just uuid ->
      Right $ UserIdentifier (Just $ UserUUID uuid) Nothing Nothing
    Nothing ->
      if isValid $ encodeUtf8 s
      then Right $ UserIdentifier Nothing Nothing (Just s)
      else Right $ UserIdentifier Nothing (Just s) Nothing

instance ToHttpApiData UserIdentifier where
  toUrlPiece (UserIdentifier (Just (UserUUID uuid)) _ _) = toText uuid
  toUrlPiece (UserIdentifier _ (Just name) _) = name
  toUrlPiece (UserIdentifier _ _ (Just email)) = email
  toUrlPiece (UserIdentifier Nothing Nothing Nothing) = ""

instance FromJSON UserIdentifier where
  parseJSON (Object obj) = do
    uuid <- obj .:? "id"
    name <- obj .:? "name"
    email <- obj .:? "email"
    return $ UserIdentifier uuid name email
  parseJSON (String s) = return $ userIdentifierFromText s
  parseJSON _ = fail "Invalid JSON"

instance ToJSON UserIdentifier where
  toJSON (UserIdentifier mId mName mEmail) = object
    [ "id" .= mId
    , "name" .= mName
    , "email" .= mEmail
    ]


userIdentifierToText :: UserIdentifier -> Text
userIdentifierToText (UserIdentifier (Just (UserUUID uuid)) _ _) = toText uuid
userIdentifierToText (UserIdentifier _ (Just name) _) = name
userIdentifierToText (UserIdentifier _ _ (Just email)) = email
userIdentifierToText (UserIdentifier Nothing Nothing Nothing) = ""


userIdentifierFromText :: Text -> UserIdentifier
userIdentifierFromText s = case readMaybe $ unpack s of
  Just uuid ->
    UserIdentifier (Just $ UserUUID uuid) Nothing Nothing
  Nothing ->
    if isValid $ encodeUtf8 s
    then UserIdentifier Nothing Nothing (Just s)
    else UserIdentifier Nothing (Just s) Nothing

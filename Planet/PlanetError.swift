enum PlanetError: Error {
    case PersistenceError
    case NetworkError
    case IPFSError
    case EthereumError
    case PlanetFeedError
    case PlanetExistsError
    case MissingTemplateError
    case AvatarError
    case PodcastCoverArtError
    case ImportPlanetError
    case ExportPlanetError
    case FileExistsError
    case FollowLocalPlanetError
    case FollowPlanetVerifyError
    case InvalidPlanetURLError
    case ENSNoContentHashError
    case DotBitNoDWebRecordError
    case DotBitIPNSResolveError
    case RenderMarkdownError
    case PublishedServiceFolderUnchangedError
    case PublishedServiceFolderPermissionError
    case MovePublishingPlanetArticleError
    case WalletConnectV2ProjectIDMissingError
    case PublicAPIError
    case KeychainSavingKeyError
    case KeychainLoadingKeyError
    case KeychainDeletingKeyError
    case KeychainGeneratingKeyError
    case KeychainImportingKeyError
    case KeychainImportingKeyExistsError
    case KeychainExportingKeyExistsError
    case InternalError
    case UnknownError(Error)
}

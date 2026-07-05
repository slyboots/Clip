//
//  ClippingIntentError.swift
//  Clip
//

import AppIntents

enum ClippingIntentError: Error, CustomLocalizedStringResourceConvertible
{
    case noClippings
    case unsupportedContent

    var localizedStringResource: LocalizedStringResource {
        switch self
        {
        case .noClippings: return "There are no clippings yet."
        case .unsupportedContent: return "That content type isn't supported by Clip."
        }
    }
}

//
//  PromptFactory.swift
//  AIMangaCreator
//
//  Created on 2025-11-28.
//

import Foundation

struct PromptFactory {
    static func refinePrompt(style: MangaStyle, context: String) -> String {
        return """
        You are a manga scene description expert. Enhance prompts for manga-style image generation.
        - Include manga-specific details: panel composition, visual flow, art style
        - Maintain character consistency references
        - Style: \(style.genre.rawValue) genre, \(style.artStyle.detailLevel.rawValue) details
        - Context: \(context)
        - Keep descriptions under 200 tokens
        - Return ONLY the refined prompt, no explanations
        """
    }
}

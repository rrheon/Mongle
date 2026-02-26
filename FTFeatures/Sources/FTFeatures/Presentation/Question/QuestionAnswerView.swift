//
//  SwiftUIView.swift
//  FTFeatures
//
//  Created by 최용헌 on 1/23/26.
//

import SwiftUI

// MARK: - Main View
struct DailyQuestionAnswerView: View {
  @State private var answer: String = ""

  var body: some View {
    ZStack {
      // 🌿 Meadow-like Background
      LinearGradient(
        colors: [
          Color(red: 1.0, green: 0.97, blue: 0.88),
          Color(red: 0.92, green: 0.96, blue: 0.90)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {

        TopBar()

        Spacer(minLength: 12)

        QuestionHeader()

        InstructionText()

        AnswerInput(answer: $answer)

        SubmitButton()

        Spacer(minLength: 20)
      }
    }
  }
}

// MARK: - Top App Bar
struct TopBar: View {
  var body: some View {
    HStack {
      // Hedgehog Avatar Placeholder
      Circle()
        .fill(Color(red: 0.94, green: 0.89, blue: 0.84))
        .frame(width: 40, height: 40)
        .overlay(
          Text("🦔")
            .font(.system(size: 20))
        )
        .overlay(
          Circle()
            .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )

      Spacer()

      Text("FamilyTree")
        .font(.caption.bold())
        .foregroundColor(Color(red: 0.55, green: 0.43, blue: 0.38))
        .tracking(2)

      Spacer()

      // Right placeholder for symmetry
      Color.clear
        .frame(width: 40, height: 40)
    }
    .padding(.horizontal)
    .padding(.top, 44)
  }
}

// MARK: - Question Header
struct QuestionHeader: View {
  var body: some View {
    Text("What made you smile today?")
      .font(.system(size: 32, weight: .bold))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 24)
      .padding(.top, 24)
  }
}

// MARK: - Instruction Text
struct InstructionText: View {
  var body: some View {
    Text("Your answer will be shared with the family meadow.")
      .font(.body.weight(.medium))
      .foregroundColor(Color.brown.opacity(0.7))
      .multilineTextAlignment(.center)
      .padding(.horizontal, 32)
      .padding(.top, 8)
      .padding(.bottom, 20)
  }
}

// MARK: - Answer Input
struct AnswerInput: View {
  @Binding var answer: String

  var body: some View {
    VStack(alignment: .trailing, spacing: 8) {
      TextEditor(text: $answer)
        .padding(16)
        .font(.system(size: 18))
        .frame(minHeight: 180)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color.white.opacity(0.6))
            .background(.ultraThinMaterial)
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(Color.brown.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 24)

      Text("Keep it heartfelt • Today's prompt")
        .font(.caption)
        .foregroundColor(Color.brown.opacity(0.5))
        .padding(.horizontal, 32)
    }
  }
}

// MARK: - Submit Button
struct SubmitButton: View {
  var body: some View {
    Button {
      print("Share with family tapped")
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "leaf.fill")
        Text("Share with Family")
          .font(.headline.bold())
      }
      .frame(maxWidth: .infinity)
      .frame(height: 56)
      .background(Color(red: 0.55, green: 0.43, blue: 0.38))
      .foregroundColor(.white)
      .clipShape(Capsule())
      .shadow(color: Color.brown.opacity(0.25), radius: 10, y: 4)
    }
    .padding(.horizontal, 24)
    .padding(.top, 32)
  }
}

// MARK: - Preview
#Preview {
  DailyQuestionAnswerView()
}

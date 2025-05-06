//
//  QuickPromptButton.swift
//  FreeChat
//
//  Created by Peter Sugihara on 9/4/23.
//  Modified for Legal Edition on 5/6/25
//

import SwiftUI

struct CapsuleButtonStyle: ButtonStyle {
  @State var hovered = false
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(hovered ? .body.bold() : .body)
      .background(
        RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .continuous)
          .strokeBorder(hovered ? Color.primary.opacity(0) : Color.primary.opacity(0.2), lineWidth: 0.5)
          .foregroundColor(Color.primary)
          .background(hovered ? Color.primary.opacity(0.1) : Color.clear)
      )
      .multilineTextAlignment(.leading) // Center-align multiline text
      .lineLimit(nil) // Allow unlimited lines
      .onHover(perform: { hovering in
        hovered = hovering
      })
      .animation(Animation.easeInOut(duration: 0.16), value: hovered)
      .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10), style: .continuous))
  }
}

struct QuickPromptButton: View {
  struct QuickPrompt: Identifiable {
    let id = UUID()
    var title: String
    var rest: String
  }
  
  static var quickPrompts = [
    QuickPrompt(
      title: "Draft a response",
      rest: "to a litigation hold notice that acknowledges receipt and outlines our preservation steps"
    ),
    QuickPrompt(
      title: "Review this contract clause",
      rest: "and identify potential risks or areas that need clarification"
    ),
    QuickPrompt(
      title: "Summarize the key points",
      rest: "of recent changes to data privacy regulations in our industry"
    ),
    QuickPrompt(
      title: "Create a checklist",
      rest: "for legal due diligence when considering an acquisition target"
    ),
    QuickPrompt(
      title: "Draft a memo",
      rest: "explaining potential legal implications of our new remote work policy"
    ),
    QuickPrompt(
      title: "Explain the difference",
      rest: "between binding arbitration and mediation for our HR department"
    ),
    QuickPrompt(
      title: "Draft an NDA",
      rest: "for a new vendor relationship involving proprietary technology"
    ),
    QuickPrompt(
      title: "Summarize case law",
      rest: "on employee non-compete agreements in our jurisdiction"
    ),
    QuickPrompt(
      title: "Draft legal risk analysis",
      rest: "for our new marketing campaign targeting minors"
    ),
    QuickPrompt(
      title: "Create a template",
      rest: "for responding to third-party subpoenas for company records"
    ),
    QuickPrompt(
      title: "Explain potential liability",
      rest: "for our company if an employee makes unauthorized statements on social media"
    ),
    QuickPrompt(
      title: "Draft talking points",
      rest: "for executive communication about pending regulatory investigation"
    ),
    QuickPrompt(
      title: "Create a framework",
      rest: "for evaluating whether an incident constitutes a reportable data breach"
    ),
    QuickPrompt(
      title: "Summarize requirements",
      rest: "for international data transfers under GDPR and other privacy laws"
    ),
    QuickPrompt(
      title: "Draft board resolution",
      rest: "approving new corporate governance policies"
    ),
    QuickPrompt(
      title: "Create a timeline",
      rest: "for implementing compliance with new industry regulations"
    ),
    QuickPrompt(
      title: "Draft internal guidance",
      rest: "on documenting attorney-client privilege communications"
    ),
    QuickPrompt(
      title: "Analyze potential issues",
      rest: "with our current intellectual property protection strategy"
    )
  ].shuffled()
  
  @Binding var input: String
  var prompt: QuickPrompt
  
  var body: some View {
    Button(action: {
      input = prompt.title + " " + prompt.rest
    }, label: {
      VStack(alignment: .leading) {
        Text(prompt.title).bold().font(.caption2).lineLimit(1)
        Text(prompt.rest).font(.caption2).lineLimit(1).foregroundColor(.secondary)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 10)
      .frame(maxWidth: .infinity, alignment: .leading)
    })
    .buttonStyle(CapsuleButtonStyle())
    .frame(maxWidth: 300)
  }
}

//struct QuickPromptButton_Previews_Container: View {
//  var p: QuickPromptButton.QuickPrompt
//  @State var input = ""
//  var body: some View {
//    QuickPromptButton(input: $input, prompt: p)
//  }
//}
//
//struct QuickPromptButton_Previews: PreviewProvider {
//  static var previews: some View {
//    ForEach(QuickPromptButton.quickPrompts) { p in
//      QuickPromptButton_Previews_Container(p: p)
//        .previewDisplayName(p.title)
//    }
//  }
//}

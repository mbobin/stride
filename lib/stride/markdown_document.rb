require 'redcarpet'

# Convert Markdown-formatted strings to JSON to send to Stride
# Currently only supports simple links
#
module Stride
  class MarkdownDocument
    def initialize(markdown)
      self.markdown = markdown
    end

    def as_json
      {
        "version": 1,
        "type": "doc",
        "content": [
          {
            "type": "paragraph",
            "content": content_blocks
          }
        ]
      }
    end

    private

    attr_accessor :markdown

    def content_blocks
      Redcarpet::Markdown.new(Renderer).render(markdown)
    end

    class Renderer < Redcarpet::Render::Base
      def preprocess(document)
        # make emojis look like links so we can use that hook
        document.gsub(/(\:\w+\:)/, '[\1]()')
      end

      def paragraph(text)
        text
      end

      def normal_text(text)
        return nil if text.to_s.size == 0

        {
          "type": "text",
          "text": text
        }.to_json + ','
      end

      def emphasis(text)
        # unwrap text that got passed through `normal_text`
        text = JSON.parse(text.sub(/,\Z/, ''))['text']

        {
          "type": "text",
          "text": text,
          "marks": [
            {
              "type": "strong"
            }
          ]
        }.to_json + ','
      end

      def image(link, title, alt_text)
        {
          "type": "text",
          "text": title || 'image',
          "marks": [
            {
              "type": "link",
              "attrs": {
                "href": link
              }
            }
          ]
        }.to_json + ','
      end

      def block_code(code, _language)
        {
          "type": "text",
          "text": code,
          "marks": [
            {
              "type": "code"
            }
          ]
        }.to_json + ','
      end

      def codespan(code)
        block_code(code, nil)
      end

      def emoji_json(emoji_name)
        {
          "type": "emoji",
          "attrs": {
            "shortName": emoji_name
          }
        }.to_json + ','
      end

      def link(link, title, content)
        # unwrap text that got passed through `normal_text`
        content = JSON.parse(content.sub(/,\Z/, ''))['text']

        if link == nil && content =~ /\:\w+\:/
          emoji_json(content)
        else
          {
            "type": "text",
            "text": content,
            "marks": [
              {
                "type": "link",
                "attrs": {
                  "href": link
                }
              }
            ]
          }.to_json + ','
        end
      end

      def linebreak
        {
          "type" => "hardBreak"
        }.to_json + ','
      end

      def postprocess(document)
        # Strip lingering `!`s from image Markdown that are passed into `normal_text`
        # instead of being used to trigger the `image` hook. Not sure what's going on.
        document = document.gsub('!"},{"type":"text","text":"image"', '"},{"type":"text","text":"image"')

        # Strip leading/trailing commas
        document = document.sub(/\A,/, '').sub(/,\Z/, '')

        # Replace empty strings with a space. This is a hack due to multiple line breaks
        # in a row followed by an image not getting formatted correctly...
        # FIXME: Should really get a couple of hardbreaks instead of a space.
        document = document.gsub('{"type":"text","text":""}', '{"type":"text", "text":" "}')

        # Return document as JSON
        JSON.parse("[#{document}]")
      end
    end
  end
end

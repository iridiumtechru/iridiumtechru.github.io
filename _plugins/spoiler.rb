module Jekyll
    class SpoilerBlock < Liquid::Block
      def initialize (tag_name, markup, tokens)
        super
        @summary = markup.strip
      end
  
      def render(context)
        output = '<details>'
        output << '<summary>'
        output << "<code>#{@summary.empty? ? 'Open' : @summary}</code>"
        output << '</summary>'
        output << '<div class="language-bash highlighter-rouge">'
        output << '<div class="highlight">'
        output << '<pre class="highlight"><code>'
        output << super
        output << '</code></pre></div></div>'
        output << '</details>'
      end
    end
end
  
Liquid::Template.register_tag('spoilerblock', Jekyll::SpoilerBlock)
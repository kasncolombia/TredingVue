module ApplicationHelper
  def nav_link(label, path, icon: nil)
    active = current_page?(path)
    cls = "w-full flex items-center gap-2.5 px-3 py-2.5 rounded-xl font-medium text-xs transition-all "
    cls += active ? "nav-active" : "text-slate-400 hover:bg-darkCard hover:text-slate-200"
    content_tag(:div) do
      link_to path, class: cls do
        svg_icon(icon) + content_tag(:span, label)
      end
    end
  end

  def svg_icon(d, cls: "w-4 h-4 flex-shrink-0")
    return "".html_safe unless d
    content_tag(:svg, class: cls, fill: "none", stroke: "currentColor", viewBox: "0 0 24 24") do
      tag.path("stroke-linecap": "round", "stroke-linejoin": "round", "stroke-width": "2", d: d)
    end
  end

  def pnl_class(value)
    value.to_f >= 0 ? "text-emerald-400" : "text-rose-400"
  end

  def direction_badge(dir)
    cls = dir == "LONG" ? "bg-emerald-500/20 text-emerald-300" : "bg-rose-500/20 text-rose-300"
    content_tag(:span, dir, class: "px-2 py-0.5 rounded text-[10px] font-bold #{cls}")
  end

  def result_badge(res)
    cls = res == "WIN" ? "bg-emerald-500/10 text-emerald-400 border border-emerald-500/20" : "bg-rose-500/10 text-rose-400 border border-rose-500/20"
    content_tag(:span, res, class: "px-2 py-0.5 rounded text-[10px] font-bold #{cls}")
  end

  def asset_logo_tag(symbol, logo_url: nil, size_cls: "w-7 h-7")
    sym = symbol.to_s.upcase.strip

    if logo_url.present?
      return image_tag(logo_url, class: "#{size_cls} rounded-full object-cover shrink-0 border border-slate-200 dark:border-slate-700", alt: sym)
    end
    
    if sym.include?("BTC")
      # Bitcoin (Orange circle with B logo)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#f7931a] flex items-center justify-center text-white shrink-0 shadow-xs font-black text-xs">
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M23.638 14.904c-1.602 6.43-8.113 10.34-14.542 8.736C2.67 22.05-1.24 15.538.362 9.11 1.962 2.67 8.475-1.24 14.902.362c6.43 1.605 10.34 8.114 8.736 14.542z" fill="#f7931a"/>
            <path d="M17.472 10.428c.245-1.637-.999-2.518-2.698-3.105l.551-2.21-1.345-.336-.537 2.155c-.354-.088-.718-.17-1.08-.25l.542-2.171-1.344-.336-.552 2.213c-.292-.067-.58-.135-.862-.206l.002-.007-1.855-.463-.358 1.436s1.0.229.978.243c.546.136.645.498.629.785l-.63 2.525c.038.01.086.024.139.047l-.142-.036-.883 3.539c-.067.166-.237.416-.62.32l-.98-.245-.512 2.052 1.75.437c.326.082.646.168.962.25l-.558 2.24 1.344.335.551-2.21c.367.1.723.192 1.072.28l-.548 2.2.1.025 1.344.336.558-2.238c2.29.434 4.013.259 4.738-1.813.584-1.668-.029-2.632-1.233-3.258.877-.202 1.538-.778 1.714-1.967zm-3.072 4.296c-.415 1.67-3.226.767-4.137.54l.738-2.958c.91.228 3.824.68 3.399 2.418zm.415-4.322c-.378 1.517-2.72.746-3.48.557l.67-2.684c.76.19 3.19.544 2.81 2.127z" fill="#ffffff"/>
          </svg>
        </div>
      HTML
    elsif sym.include?("ETH")
      # Ethereum (Purple circle with diamond logo)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#627eea] flex items-center justify-center text-white shrink-0 shadow-xs">
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M11.999 0l-6.62 11.007L12 14.935l6.621-3.928z" fill="#ffffff" fill-opacity="0.6"/>
            <path d="M11.999 0L5.379 11.007 12 14.935z" fill="#ffffff"/>
            <path d="M11.999 16.173l-6.62-3.928L12 24l6.621-11.755z" fill="#ffffff" fill-opacity="0.6"/>
            <path d="M11.999 16.173L5.379 12.245 12 24z" fill="#ffffff"/>
          </svg>
        </div>
      HTML
    elsif sym.include?("SOL")
      # Solana (Purple/Cyan gradient circle)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-gradient-to-tr from-[#9945FF] to-[#14F195] flex items-center justify-center text-white shrink-0 shadow-xs font-black text-[10px]">
          SOL
        </div>
      HTML
    elsif sym.include?("XAU") || sym.include?("GOLD") || sym.include?("MGC") || sym.include?("GC")
      # Gold / XAU / MGC (Amber gold bars)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-amber-500 flex items-center justify-center text-white shrink-0 shadow-xs">
          <span class="material-symbols-outlined text-[16px]">view_in_ar</span>
        </div>
      HTML
    elsif sym.include?("MNQ") || sym.include?("NQ") || sym.include?("NASDAQ")
      # Nasdaq / MNQ (Cyan N circle)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#00a4e4] flex items-center justify-center text-white shrink-0 shadow-xs font-black text-xs">
          <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 14h-2V8h2v8zm4 0h-2V6h2v10zM9 16H7v-6h2v6z" fill="#ffffff"/>
          </svg>
        </div>
      HTML
    elsif sym.include?("META")
      # Meta (Blue infinity logo)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#0466c8] flex items-center justify-center text-white shrink-0 shadow-xs">
          <svg class="w-4 h-4 fill-current" viewBox="0 0 24 24">
            <path d="M12 9.246c-1.397-1.748-3.08-2.74-4.814-2.74C4.195 6.506 2 8.79 2 12c0 3.21 2.195 5.494 5.186 5.494 1.734 0 3.417-.992 4.814-2.74 1.397 1.748 3.08 2.74 4.814 2.74 2.991 0 5.186-2.284 5.186-5.494 0-3.21-2.195-5.494-5.186-5.494-1.734 0-3.417.992-4.814 2.74zm-4.814 6.74c-2.025 0-3.682-1.492-3.682-3.986 0-2.494 1.657-3.986 3.682-3.986 1.258 0 2.502.775 3.593 2.14-1.09 1.365-2.335 2.14-3.593 2.14zm9.628 0c-1.258 0-2.502-.775-3.593-2.14 1.09-1.365 2.335-2.14 3.593-2.14 2.025 0 3.682 1.492 3.682 3.986 0 2.494-1.657 3.986-3.682 3.986z" fill="#ffffff"/>
          </svg>
        </div>
      HTML
    elsif sym.include?("NVDA")
      # Nvidia (Green eye)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#76b900] flex items-center justify-center text-white shrink-0 shadow-xs font-black text-xs">
          N
        </div>
      HTML
    elsif sym.include?("EUR")
      # EUR (EU Flag blue circle with stars)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-[#003399] flex items-center justify-center text-white shrink-0 shadow-xs font-black text-[10px]">
          €
        </div>
      HTML
    elsif sym.include?("AAPL")
      # Apple (Black circle with white apple)
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full bg-slate-900 flex items-center justify-center text-white shrink-0 shadow-xs">
          <svg class="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.32c.67-.82 1.12-1.95.99-3.09-1 .04-2.17.67-2.88 1.5-.62.72-1.16 1.87-1.01 2.99 1.11.09 2.23-.58 2.9-1.4z"/>
          </svg>
        </div>
      HTML
    else
      # Dynamic Fallback Badge with Initials & Clean Color
      color_hash = (sym.sum % 5)
      bg_cls = case color_hash
               when 0 then "bg-indigo-600"
               when 1 then "bg-purple-600"
               when 2 then "bg-teal-600"
               when 3 then "bg-sky-600"
               else "bg-slate-700"
               end
      init = sym.split('/')[0].to_s[0..2]
      <<-HTML.html_safe
        <div class="#{size_cls} rounded-full #{bg_cls} flex items-center justify-center text-white shrink-0 shadow-xs font-black text-[10px] tracking-tighter">
          #{init}
        </div>
      HTML
    end
  end
end

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
end

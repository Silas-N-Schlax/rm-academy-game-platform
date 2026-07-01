module ScreenControlHelper
  def scroll_button_into_view(content)
    button = find_button(content, visible: :all)
    execute_script("arguments[0].scrollIntoView(true);", button)
    button
  end

  def scroll_link_into_view(content)
    link = find_link(content, visible: :all)
    execute_script("arguments[0].scrollIntoView(true);", link)
    link
  end
end

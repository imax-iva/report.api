defmodule Report.Web.PageView do
  @moduledoc """
  Sample view for Pages controller.
  """
  use Report.Web, :view
  alias Report.Web.PageView

  def render("index.json", %{pages: pages}) do
    render_many(pages, PageView, "page.json")
  end

  def render("show.json", %{page: page}) do
    render_one(page, PageView, "page.json")
  end

  def render("page.json", _assigns) do
    %{page: %{detail: "This is page."}}
  end
end

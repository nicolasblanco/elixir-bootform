defmodule Bootform do
  @moduledoc ~S"""
    Bootform is inspired by simple_form from rails and allow an easier way to render form
    using bootstrap 4 semantic.

      input form, :email, "Your email", type: :email

    will render

      <div class="form-group has-danger">
          <label for="helloEmail">Your email</label>
          <input class="form-control" id="helloEmail" name="hello[email]" type="text">
          <div class="form-control-feedback">can&#39;t be blank</div>
      </div>
  """

  alias Phoenix.HTML.Form
  alias Phoenix.HTML.Tag
  alias Bootform.AttributeHelper
  alias Bootform.Errors

  @wrapper_class "form-group"
  @wrapper_checkbox_class "form-check"
  @error_class "has-danger"
  @input_class "form-control"
  @input_error_class "is-invalid"

  @doc """
  Render text input using bootstrap tags

  ## Examples

  You can use it this way

  ```
  input form, :email, "Your email", type: :email
  ```

  You can ommit label and options

  ```
  input form, :email
  ```
  """
  @spec input(Phoenix.HTML.Form.t(), Atom.t(), String.t(), List.t()) :: {:safe, String.t()}
  def input(form, field, label, opts) do
    id = AttributeHelper.id(form, field)
    options = Keyword.get(opts, :options)

    wrap(form, field, label, label_class: Keyword.get(opts, :label_class)) do
      type =
        if options do
          :select
        else
          Keyword.get(opts, :type)
        end

      input_class =
        if Errors.has_error?(form, field) do
          @input_class <> " " <> @input_error_class
        else
          @input_class
        end

      opts =
        Keyword.delete(opts, :type)
        |> Keyword.delete(:label_class)
        |> Keyword.delete(:options)
        |> Keyword.put_new(:id, id)
        |> Keyword.put_new(:class, input_class)
        |> Keyword.put_new(:phx_feedback_for, id)

      case type do
        :email -> Form.email_input(form, field, opts)
        :password -> Form.password_input(form, field, opts)
        :textarea -> Form.textarea(form, field, opts)
        :select -> Form.select(form, field, options, opts)
        :number -> Form.number_input(form, field, opts)
        _ -> Form.text_input(form, field, opts)
      end
    end
  end

  def input(form, field, opts) when is_list(opts) do
    input(form, field, false, opts)
  end

  def input(form, field, label) when is_binary(label) do
    input(form, field, label, [])
  end

  def input(form, field) do
    input(form, field, false, [])
  end

  @doc """
  Render textarea input using bootstrap tags
  """
  @spec textarea(Phoenix.HTML.Form.t(), Atom.t(), String.t(), List.t()) :: {:safe, String.t()}
  def textarea(form, field, label \\ false, opts \\ []) do
    input(form, field, label, [type: :textarea] ++ opts)
  end

  @doc """
  Render a checkbox with label
  """
  @spec checkbox(Phoenix.HTML.Form.t(), Atom.t(), String.t(), List.t()) :: {:safe, String.t()}
  def checkbox(form, field, label \\ false, opts \\ []) do
    class =
      case Errors.has_error?(form, field) do
        true -> @wrapper_checkbox_class <> " " <> @error_class
        _ -> @wrapper_checkbox_class
      end

    id = AttributeHelper.id(form, field)

    Tag.content_tag :div, class: class, phx_feedback_for: id do
      Tag.content_tag :label, class: "form-check-label" do
        [
          Form.checkbox(
            form,
            field,
            opts ++
              [
                class: "form-check-input",
                id: id
              ]
          ),
          label
        ]
      end
    end
  end

  @doc """
    Render a submit button
  """
  @spec submit(String.t()) :: {:safe, String.t()}
  def submit(label) do
    Tag.content_tag :div, class: @wrapper_class do
      Tag.content_tag(:button, label, type: "submit", class: "btn btn-primary")
    end
  end

  @doc """
  Render a form group
  """
  def form_group(form, field, do: block) do
    Tag.content_tag :div, class: form_group_class(form, field) do
      block
    end
  end

  defp form_group_class(form, field) do
    if Errors.has_error?(form, field) do
      @wrapper_class <> " " <> @error_class
    else
      @wrapper_class
    end
  end

  defp wrap(form, field, label, opts, do: block) do
    id = AttributeHelper.id(form, field)
    label_class = Keyword.get(opts, :label_class)
    opts = Keyword.delete(opts, :label_class)

    {opts, help} =
      if Errors.has_error?(form, field) do
        {
          opts ++ [class: @wrapper_class <> " " <> @error_class, phx_feedback_for: id],
          Tag.content_tag(error_content_tag(), Errors.get_error(form, field),
            class: "invalid-feedback",
            phx_feedback_for: id
          )
        }
      else
        {
          Keyword.put_new(opts, :class, @wrapper_class),
          ""
        }
      end

    Tag.content_tag :div, opts do
      [
        if label !== false do
          Tag.content_tag(:label, label, class: label_class || label_class(), for: id)
        else
          ""
        end,
        block,
        help
      ]
    end
  end

  defp error_content_tag() do
    Application.get_env(:bootform, :error_content_tag) || :small
  end

  defp label_class() do
    Application.get_env(:bootform, :label_class) || "form-control-label"
  end
end

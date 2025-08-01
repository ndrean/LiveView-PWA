defmodule LiveviewPwaWeb.Pwa do
  @moduledoc false

  use Phoenix.Component
  use LiveviewPwaWeb, :verified_routes

  attr :height, :integer, default: 20, doc: "Height of the SVG icon"
  attr :class, :string, doc: "CSS class for the SVG icon"

  def svg(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      width={round(@height * 2.65)}
      height={@height}
      class={@class}
      baseProfile="full"
      enable-background="new 0 0 1952 734.93"
      version="1.1"
      viewBox="0 0 1952 734.93"
      xml:space="preserve"
    >
      <g>
        <path
          fill="#FFF"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 1436.62,603.304L 1493.01,460.705L 1655.83,460.705L 1578.56,244.39L 1675.2,0.000528336L 1952,734.933L 1747.87,734.933L 1700.57,603.304L 1436.62,603.304 Z"
        />
        <path
          fill="#5A0FC8"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 1262.47,734.935L 1558.79,0.00156593L 1362.34,0.0025425L 1159.64,474.933L 1015.5,0.00351906L 864.499,0.00351906L 709.731,474.933L 600.585,258.517L 501.812,562.819L 602.096,734.935L 795.427,734.935L 935.284,309.025L 1068.63,734.935L 1262.47,734.935 Z"
        />
        <path
          fill="#FFF"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 186.476,482.643L 307.479,482.643C 344.133,482.643 376.772,478.552 405.396,470.37L 436.689,373.962L 524.148,104.516C 517.484,93.9535 509.876,83.9667 501.324,74.5569C 456.419,24.852 390.719,0.000406265 304.222,0.000406265L -3.8147e-006,0.000406265L -3.8147e-006,734.933L 186.476,734.933L 186.476,482.643 Z M 346.642,169.079C 364.182,186.732 372.951,210.355 372.951,239.95C 372.951,269.772 365.238,293.424 349.813,310.906C 332.903,330.331 301.766,340.043 256.404,340.043L 186.476,340.043L 186.476,142.598L 256.918,142.598C 299.195,142.598 329.103,151.425 346.642,169.079 Z"
        />
      </g>
    </svg>
    <%!-- <svg
      xmlns="http://www.w3.org/2000/svg"
      xmlns:xlink="http://www.w3.org/1999/xlink"
      width={round(@height * 2.65)}
      height={@height}
      viewBox="0 0 1952 734.93"
      xml:space="preserve"
      class={@class}
    >
      <use xlink:href="#pwa-icon" />
      baseProfile="full" enable-background="new 0 0 1952 734.93" version="1.1" viewBox="0 0 1952 734.93"
      xml:space="preserve">
      <g>
        <path
          fill="#FFF"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 1436.62,603.304L 1493.01,460.705L 1655.83,460.705L 1578.56,244.39L 1675.2,0.000528336L 1952,734.933L 1747.87,734.933L 1700.57,603.304L 1436.62,603.304 Z"
        />
        <path
          fill="#5A0FC8"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 1262.47,734.935L 1558.79,0.00156593L 1362.34,0.0025425L 1159.64,474.933L 1015.5,0.00351906L 864.499,0.00351906L 709.731,474.933L 600.585,258.517L 501.812,562.819L 602.096,734.935L 795.427,734.935L 935.284,309.025L 1068.63,734.935L 1262.47,734.935 Z"
        />
        <path
          fill="#FFF"
          fill-opacity="1"
          stroke-linejoin="round"
          stroke-width=".2"
          d="M 186.476,482.643L 307.479,482.643C 344.133,482.643 376.772,478.552 405.396,470.37L 436.689,373.962L 524.148,104.516C 517.484,93.9535 509.876,83.9667 501.324,74.5569C 456.419,24.852 390.719,0.000406265 304.222,0.000406265L -3.8147e-006,0.000406265L -3.8147e-006,734.933L 186.476,734.933L 186.476,482.643 Z M 346.642,169.079C 364.182,186.732 372.951,210.355 372.951,239.95C 372.951,269.772 365.238,293.424 349.813,310.906C 332.903,330.331 301.766,340.043 256.404,340.043L 186.476,340.043L 186.476,142.598L 256.918,142.598C 299.195,142.598 329.103,151.425 346.642,169.079 Z"
        />
      </g>
    </svg> --%>
    """
  end
end

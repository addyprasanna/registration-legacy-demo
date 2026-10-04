module ApplicationHelper
  def format_money(cents, currency = "USD")
    symbol = currency == "CAD" ? "CA$" : "$"
    "#{symbol}#{number_with_precision(cents.to_i / 100.0, precision: 2, delimiter: ',')}"
  end

  def format_date(value)
    value&.strftime("%b %-d, %Y")
  end

  def status_badge(status)
    style = case status.to_s
            when "approved", "submitted", "filed", "issued", "delivered", "released", "not_required" then "badge-accent"
            when "pending", "in_review", "scheduled", "active" then "badge-muted"
            when "rejected", "expired", "voided" then "badge-danger"
            else "badge-outline"
            end
    content_tag(:span, status.to_s.humanize, class: style)
  end

  def jurisdiction_name(code)
    Jurisdictions.for(code).display_name
  rescue Jurisdictions::UnknownJurisdiction
    code
  end

  def line_items_for(record)
    Array(record.fee_breakdown).map { |item| item.with_indifferent_access }
  end
end

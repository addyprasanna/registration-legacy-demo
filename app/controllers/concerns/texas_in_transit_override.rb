module TexasInTransitOverride
  def temp_tag_days_for(jurisdiction, input)
    return 30 if jurisdiction.code == "TX" && input.out_of_state_buyer?

    jurisdiction.temp_tag_valid_days(input)
  end
end

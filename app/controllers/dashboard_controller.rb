class DashboardController < ApplicationController
  def show
    @registrations_pending = Registrations::Registration.where(status: %w[draft submitted]).count
    @temp_tags_expiring = TempTags::TempTag.where(status: "active").where(expires_on: Date.current..7.days.from_now.to_date).count
    @liens_pending = LienFilings::LienFiling.where(status: "pending").count
    @titles_in_review = Titling::TitleApplication.where(status: "in_review").count
    @recent_registrations = Registrations::Registration.includes(vehicle: :customer).order(created_at: :desc).limit(5)
    @recent_tags = TempTags::TempTag.includes(vehicle: :customer).order(created_at: :desc).limit(5)
  end
end

SEED_TIME = Time.utc(2026, 10, 4, 12, 0, 0)
SEED_DATE = SEED_TIME.to_date
FIRST_NAMES = %w[
  Avery Jordan Morgan Riley Casey Taylor Quinn Reese Cameron Skyler Dakota Parker Rowan Emerson
  Finley Sage Kendall Ellis Peyton River Alex Jamie Drew Devon Rory Blair Arden Frankie Micah Logan
].freeze
LAST_NAMES = %w[
  Reed Kim Patel Morgan Brooks Rivera Chen Hayes Bennett Foster Diaz Sullivan Jameson Clarke
  Alexander Bell Cooper Evans Flores Green Howard Jenkins King Lewis Murphy Nelson Ortiz Perry Powell Ramirez
].freeze
STREETS = %w[
  Harbor\ Blvd Market\ St Summit\ Ave Lakeview\ Dr Mission\ St Cedar\ Ave Broadway Juniper\ Way
  Pine\ St Riverside\ Dr Bayview\ Rd Union\ St
].freeze
VIN_ALPHABET = "0123456789ABCDEFGHJKLMNPRSTUVWXYZ".chars.freeze
MODEL_CURB_WEIGHTS = {
  "Air Pure" => 4_800,
  "Air Touring" => 4_900,
  "Air Grand Touring" => 5_000,
  "Air Sapphire" => 5_400,
  "Gravity Touring" => 5_700,
  "Gravity Grand Touring" => 6_000
}.freeze
WEIGHT_VARIANTS = [-100, -50, 0, 50, 100].freeze
TEMP_TAG_BOUNDARY_OFFSETS = [-1, 0, 1].freeze
MONTH_END_TAG_VEHICLE_INDICES = [29, 59].freeze
FINANCING_DISTRIBUTION = (
  Array.new(42, "cash") +
  Array.new(31, "loan") +
  Array.new(15, "lease") +
  Array.new(12, "refinance")
).freeze
COLORS = %w[Cosmos Silver Stellar White Obsidian].freeze

JURISDICTION_PROFILES = {
  "CA" => { city: "Oakland", postal_code: "94612", area_code: "510", region: :west },
  "TX" => { city: "Austin", postal_code: "78701", area_code: "512", region: :southwest },
  "FL" => { city: "Miami", postal_code: "33130", area_code: "305", region: :southeast },
  "NY" => { city: "New York", postal_code: "10013", area_code: "212", region: :northeast },
  "WA" => { city: "Seattle", postal_code: "98101", area_code: "206", region: :west },
  "ON" => { city: "Toronto", postal_code: "M5V 2T6", area_code: "416", region: :ontario },
  "DC" => { city: "Washington", postal_code: "20001", area_code: "202", region: :northeast },
  "AL" => { city: "Birmingham", postal_code: "35203", area_code: "205", region: :southeast },
  "AK" => { city: "Anchorage", postal_code: "99501", area_code: "907", region: :alaska },
  "AZ" => { city: "Phoenix", postal_code: "85004", area_code: "602", region: :mountain },
  "AR" => { city: "Little Rock", postal_code: "72201", area_code: "501", region: :southwest },
  "CO" => { city: "Denver", postal_code: "80202", area_code: "303", region: :mountain },
  "CT" => { city: "Hartford", postal_code: "06103", area_code: "860", region: :northeast },
  "DE" => { city: "Wilmington", postal_code: "19801", area_code: "302", region: :northeast },
  "GA" => { city: "Atlanta", postal_code: "30303", area_code: "404", region: :southeast },
  "HI" => { city: "Honolulu", postal_code: "96813", area_code: "808", region: :hawaii },
  "ID" => { city: "Boise", postal_code: "83702", area_code: "208", region: :mountain },
  "IL" => { city: "Chicago", postal_code: "60601", area_code: "312", region: :midwest },
  "IN" => { city: "Indianapolis", postal_code: "46204", area_code: "317", region: :midwest },
  "IA" => { city: "Des Moines", postal_code: "50309", area_code: "515", region: :midwest },
  "KS" => { city: "Wichita", postal_code: "67202", area_code: "316", region: :midwest },
  "KY" => { city: "Louisville", postal_code: "40202", area_code: "502", region: :midwest },
  "LA" => { city: "New Orleans", postal_code: "70112", area_code: "504", region: :southeast },
  "ME" => { city: "Portland", postal_code: "04101", area_code: "207", region: :northeast },
  "MD" => { city: "Baltimore", postal_code: "21201", area_code: "410", region: :northeast },
  "MA" => { city: "Boston", postal_code: "02108", area_code: "617", region: :northeast },
  "MI" => { city: "Detroit", postal_code: "48226", area_code: "313", region: :midwest },
  "MN" => { city: "Minneapolis", postal_code: "55401", area_code: "612", region: :midwest },
  "MS" => { city: "Jackson", postal_code: "39201", area_code: "601", region: :southeast },
  "MO" => { city: "St. Louis", postal_code: "63101", area_code: "314", region: :midwest },
  "MT" => { city: "Billings", postal_code: "59101", area_code: "406", region: :mountain },
  "NE" => { city: "Omaha", postal_code: "68102", area_code: "402", region: :midwest },
  "NV" => { city: "Las Vegas", postal_code: "89101", area_code: "702", region: :mountain },
  "NH" => { city: "Manchester", postal_code: "03101", area_code: "603", region: :northeast },
  "NJ" => { city: "Jersey City", postal_code: "07302", area_code: "201", region: :northeast },
  "NM" => { city: "Albuquerque", postal_code: "87102", area_code: "505", region: :mountain },
  "NC" => { city: "Charlotte", postal_code: "28202", area_code: "704", region: :southeast },
  "ND" => { city: "Fargo", postal_code: "58102", area_code: "701", region: :midwest },
  "OH" => { city: "Columbus", postal_code: "43215", area_code: "614", region: :midwest },
  "OK" => { city: "Oklahoma City", postal_code: "73102", area_code: "405", region: :southwest },
  "OR" => { city: "Portland", postal_code: "97205", area_code: "503", region: :west },
  "PA" => { city: "Philadelphia", postal_code: "19103", area_code: "215", region: :northeast },
  "RI" => { city: "Providence", postal_code: "02903", area_code: "401", region: :northeast },
  "SC" => { city: "Charleston", postal_code: "29401", area_code: "843", region: :southeast },
  "SD" => { city: "Sioux Falls", postal_code: "57104", area_code: "605", region: :midwest },
  "TN" => { city: "Nashville", postal_code: "37219", area_code: "615", region: :southeast },
  "UT" => { city: "Salt Lake City", postal_code: "84111", area_code: "801", region: :mountain },
  "VT" => { city: "Burlington", postal_code: "05401", area_code: "802", region: :northeast },
  "VA" => { city: "Richmond", postal_code: "23219", area_code: "804", region: :southeast },
  "WV" => { city: "Charleston", postal_code: "25301", area_code: "304", region: :southeast },
  "WI" => { city: "Milwaukee", postal_code: "53202", area_code: "414", region: :midwest },
  "WY" => { city: "Cheyenne", postal_code: "82001", area_code: "307", region: :mountain },
  "BC" => { city: "Vancouver", postal_code: "V6B 4Y8", area_code: "604", region: :british_columbia },
  "QC" => { city: "Montreal", postal_code: "H3A 1A1", area_code: "514", region: :quebec }
}.freeze

REGIONAL_DELIVERY_CENTERS = {
  west: %w[Newark,\ CA Seattle,\ WA Portland,\ OR],
  southwest: %w[Austin,\ TX Dallas,\ TX Phoenix,\ AZ],
  southeast: %w[Miami,\ FL Atlanta,\ GA Charlotte,\ NC],
  northeast: %w[New\ York,\ NY Boston,\ MA Washington,\ DC],
  midwest: %w[Chicago,\ IL Detroit,\ MI Minneapolis,\ MN],
  mountain: %w[Denver,\ CO Salt\ Lake\ City,\ UT Las\ Vegas,\ NV],
  alaska: ["Anchorage, AK"],
  hawaii: ["Honolulu, HI"],
  ontario: ["Toronto, ON"],
  british_columbia: ["Vancouver, BC"],
  quebec: ["Montreal, QC"]
}.freeze

COUNTY_TABLES = {
  "CA" => ["LOS ANGELES", "SAN FRANCISCO", "ALAMEDA", "SAN DIEGO"].freeze,
  "TX" => %w[TRAVIS HARRIS DALLAS BEXAR].freeze,
  "NY" => Jurisdictions::NewYork::MCTD_COUNTIES,
  "WA" => CustomerAccounts::Vehicle::WA_RTA_COUNTIES
}.freeze

raise "Jurisdiction profile table is incomplete" unless JURISDICTION_PROFILES.keys.sort == Jurisdictions.codes.sort

rng = Random.new(20261020)
used_emails = {}
used_vins = {}

Jurisdictions.codes.each_with_index do |code, index|
  profile = JURISDICTION_PROFILES.fetch(code)
  first_name = FIRST_NAMES.sample(random: rng)
  last_name = LAST_NAMES.sample(random: rng)
  email = "#{first_name.downcase}.#{last_name.downcase}@example.com"
  while used_emails.key?(email)
    last_name = LAST_NAMES.sample(random: rng)
    email = "#{first_name.downcase}.#{last_name.downcase}@example.com"
  end
  used_emails[email] = true

  customer_attributes = {
    first_name: first_name,
    last_name: last_name,
    email: email,
    phone: "+1-#{profile.fetch(:area_code)}-#{rng.rand(200..999)}-#{format('%04d', rng.rand(10_000))}",
    address_line1: "#{rng.rand(100..9_999)} #{STREETS.sample(random: rng)}",
    city: profile.fetch(:city),
    jurisdiction_code: code,
    postal_code: profile.fetch(:postal_code)
  }
  customer = CustomerAccounts::Customer.find_or_create_by!(customer_number: "LC-#{format('%06d', 100_001 + index)}") do |record|
    record.assign_attributes(customer_attributes)
  end

  vehicle_count = index % 3 == 0 ? 2 : 1
  vehicle_count.times do |offset|
    vehicle_index = index * 2 + offset + 1
    vin = loop do
      candidate = "5LV#{Array.new(14) { VIN_ALPHABET[rng.rand(VIN_ALPHABET.length)] }.join}"
      next if used_vins.key?(candidate)

      used_vins[candidate] = true
      break candidate
    end
    financing = FINANCING_DISTRIBUTION.sample(random: rng)
    lienholder_last_name = LAST_NAMES.sample(random: rng)
    county_options = COUNTY_TABLES[code]
    county = if rng.rand(2).zero? && county_options
               county_options.sample(random: rng)
             end
    model = CustomerAccounts::Vehicle::MODELS.sample(random: rng)
    weight = if model == "Gravity Grand Touring"
               MODEL_CURB_WEIGHTS.fetch(model)
             else
               MODEL_CURB_WEIGHTS.fetch(model) + WEIGHT_VARIANTS.sample(random: rng)
             end
    vehicle_attributes = {
      customer: customer,
      model: model,
      model_year: rng.rand(2022..2026),
      exterior_color: COLORS.sample(random: rng),
      weight_lbs: weight,
      purchase_price_cents: rng.rand(6_900_000..25_000_000),
      powertrain: "bev",
      financing: financing,
      lienholder_name: financing == "cash" ? nil : "#{lienholder_last_name} Financial",
      lienholder_elt: true,
      usage: rng.rand(3).zero? ? "commercial" : "personal",
      county: county,
      delivery_date: SEED_DATE - rng.rand(0..45)
    }
    vehicle = CustomerAccounts::Vehicle.find_or_create_by!(vin: vin) do |record|
      record.assign_attributes(vehicle_attributes)
    end

    unless vehicle.registrations.exists?
      quote = Registrations::FeeCalculator.call(vehicle: vehicle)
      registration = Registrations::Registration.create!(
        vehicle: vehicle,
        jurisdiction_code: code,
        status: "draft",
        currency: quote.jurisdiction.currency,
        fee_breakdown: quote.line_items.map { |item| { code: item.code, label: item.label, amount_cents: item.amount_cents } },
        registration_fee_cents: quote.registration_fee_cents,
        ev_surcharge_cents: quote.ev_surcharge_cents,
        total_cents: quote.total_cents
      )
      if vehicle_index % 3 == 0
        Registrations::SubmissionService.call(registration, at: SEED_TIME + vehicle_index)
      elsif vehicle_index % 5 == 0
        registration.update!(status: "approved")
      end
    end

    boundary_tag = (vehicle_index % 5).zero?
    month_end_tag = MONTH_END_TAG_VEHICLE_INDICES.include?(vehicle_index)
    if ((vehicle_index % 4).zero? || boundary_tag || month_end_tag) && !vehicle.temp_tags.exists?
      issue_date = vehicle.delivery_date
      if boundary_tag
        target_expiry = SEED_DATE + TEMP_TAG_BOUNDARY_OFFSETS.fetch(vehicle_index % 3)
        boundary_input = Jurisdictions::QuoteInput.new(
          jurisdiction: code,
          weight_lbs: vehicle.weight_lbs,
          purchase_price_cents: vehicle.purchase_price_cents,
          powertrain: vehicle.powertrain,
          financing: vehicle.financing,
          lienholder_elt: vehicle.lienholder_elt,
          buyer_jurisdiction: code,
          county: vehicle.county,
          usage: vehicle.usage,
          delivery_date: SEED_DATE
        )
        expiry_span = Jurisdictions.for(code).temp_tag_expires_on(boundary_input) - SEED_DATE
        issue_date = target_expiry - expiry_span
      elsif month_end_tag
        issue_date = SEED_DATE.prev_month.end_of_month
      end
      TempTags::IssueService.call(vehicle: vehicle, issue_date: issue_date, at: SEED_TIME + vehicle_index)
    end

    unless vehicle.lien_filings.exists?
      input = Jurisdictions::QuoteInput.new(
        jurisdiction: code,
        financing: vehicle.financing,
        lienholder_elt: vehicle.lienholder_elt,
        buyer_jurisdiction: code
      )
      result = LienFilings::DeterminationService.call(input)
      filing = LienFilings::LienFiling.create!(
        vehicle: vehicle,
        jurisdiction_code: code,
        financing: vehicle.financing,
        lienholder_name: vehicle.lienholder_name,
        elt_participant: vehicle.lienholder_elt,
        required: result.required,
        filing_method: result.filing_method,
        reason: result.reason,
        status: result.required ? "pending" : "not_required"
      )
      ::StatusEvent.create!(
        vehicle: vehicle,
        domain: "lien_filings",
        subject_type: filing.class.name,
        subject_id: filing.id,
        event: "created",
        to_status: filing.status,
        occurred_at: SEED_TIME + vehicle_index
      )
    end

    filing = vehicle.lien_filings.find_by(status: "pending")
    if filing && [0, 3].include?(vehicle_index % 4)
      LienFilings::FilingService.call(filing, at: SEED_TIME + vehicle_index + 1)
    end

    application = vehicle.title_applications.where.not(status: "rejected").first
    unless application
      application = Titling::TitleApplication.create!(
        vehicle: vehicle,
        jurisdiction_code: code,
        application_number: "TA-#{code}-#{format('%06d', Titling::TitleApplication.count + 1)}",
        status: "draft",
        status_history: [{ "status" => "draft", "at" => SEED_TIME.iso8601 }]
      )
      ::StatusEvent.create!(
        vehicle: vehicle,
        domain: "titling",
        subject_type: application.class.name,
        subject_id: application.id,
        event: "created",
        to_status: application.status,
        occurred_at: SEED_TIME
      )
    end
    target_step = vehicle_index % 4
    tracker = Titling::StatusTracker.new(application)
    while Titling::StatusTracker::FLOW.index(application.status) < target_step
      current_step = Titling::StatusTracker::FLOW.index(application.status)
      tracker.advance!(at: SEED_TIME + vehicle_index + current_step + 1)
    end

    delivery_center = REGIONAL_DELIVERY_CENTERS.fetch(profile.fetch(:region)).sample(random: rng)
    DealerPortal::Delivery.find_or_create_by!(vehicle: vehicle) do |delivery|
      delivery.delivery_center = delivery_center
      delivery.scheduled_on = vehicle.delivery_date
      delivery.status = vehicle.temp_tags.exists? || vehicle_index.even? ? "delivered" : "scheduled"
    end
  end
end

RegistrationQuoteService::SUPPORTED_STATES.each do |code|
  GoRouting::Route.find_or_create_by!(jurisdiction_code: code) do |route|
    route.mode = "legacy"
  end
end

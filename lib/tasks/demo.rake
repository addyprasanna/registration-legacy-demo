namespace :demo do
  desc "Create a fresh financed (loan) California customer and vehicle with no " \
      "registrations, lien filings, or title applications; prints the vehicle ID"
  task fresh_vehicle: :environment do
    suffix = format("%06d", Time.current.to_i % 1_000_000)

    customer = CustomerAccounts::Customer.create!(
      customer_number: "LC-9#{suffix}",
      first_name: "Demo",
      last_name: "Customer",
      email: "demo+#{suffix}@lucidvehicles.example",
      city: "Los Angeles",
      jurisdiction_code: "CA",
      postal_code: "90001"
    )

    vin_alphabet = "0123456789ABCDEFGHJKLMNPRSTUVWXYZ".chars
    vin = loop do
      candidate = "5LV#{Array.new(14) { vin_alphabet.sample }.join}"
      break candidate unless CustomerAccounts::Vehicle.exists?(vin: candidate)
    end

    vehicle = CustomerAccounts::Vehicle.create!(
      customer: customer,
      vin: vin,
      model: "Air Touring",
      model_year: 2026,
      weight_lbs: 4_900,
      purchase_price_cents: 8_500_000,
      powertrain: "bev",
      financing: "loan",
      lienholder_name: "Lucid Financial",
      lienholder_elt: true,
      usage: "personal",
      county: "LOS ANGELES",
      delivery_date: Date.current
    )

    puts "vehicle_id=#{vehicle.id}"
  end
end

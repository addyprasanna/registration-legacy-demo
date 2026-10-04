namespace :golden do
  desc "Replay fixtures/recorded_requests.json through the quote service and write fixtures/expected_responses.json"
  task capture: :environment do
    input_path = Rails.root.join("fixtures/recorded_requests.json")
    output_path = Rails.root.join("fixtures/expected_responses.json")

    requests = JSON.parse(File.read(input_path))
    responses = requests.map do |entry|
      result = RegistrationQuoteService.call(entry.fetch("body"))
      {
        "id" => entry.fetch("id"),
        "status" => Rack::Utils.status_code(result.status),
        "body" => result.body.as_json
      }
    end

    File.write(output_path, "#{JSON.pretty_generate(responses)}\n")
    puts "Wrote #{responses.size} responses to #{output_path.relative_path_from(Rails.root)}"
  end
end

require 'spec_helper'

describe HealthCheck do

  describe ".did_health_check_occur?" do
    context 'when last health check occurs after threshold value' do
      it "returns true" do
        check = HealthCheck.create!(time_of_last_check: Time.now)

        result = HealthCheck.did_health_check_occur?
        expect(result).to eq true
      end
    end

    context 'when last health check occurs before threshold value' do
      it "returns false" do
        check = HealthCheck.create!(time_of_last_check: Time.now - HealthCheck::THRESHOLD - 1.minute)

        result = HealthCheck.did_health_check_occur?
        expect(result).to eq false
      end
    end
  end
end

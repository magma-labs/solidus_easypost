# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Spree::Stock::Estimator, :vcr do
  if SolidusSupport.solidus_gem_version < Gem::Version.new("1.3")
    let(:estimator) { described_class.new(shipment.order) }
  else
    let(:estimator) { described_class.new }
  end

  let!(:shipment) { create :shipment }
  let(:package) { shipment.to_package }

  describe '#shipping_rates' do
    subject { estimator.shipping_rates package }

    context 'rates are found' do
      context 'shipping methods exist' do
        before { create_shipping_methods }

        it 'create no new shipping methods' do
          expect { subject }.to_not change { Spree::ShippingMethod.count }
        end

        context 'shipping methods are front end visible' do
          let(:rate_names) { ["USPS Express", "USPS First", "USPS ParcelSelect", "USPS Priority"] }
          let(:rate_costs) { [3.07, 5.54, 6.09, 25.21] }

          it 'has the correct names' do
            names = subject.map(&:name).sort
            expect(names).to eq rate_names
          end

          it 'has the correct costs' do
            costs = subject.map(&:cost).sort
            expect(costs).to eq rate_costs
          end
        end

        context 'shipping methods are not front end visible' do
          before { Spree::ShippingMethod.find_each { |x| x.update!(available_to_users: false) } }
          it { is_expected.to be_empty }
        end
      end

      context 'shipping methods dont exist' do
        it { is_expected.to be_empty } # new shipping methods are backend only

        it 'creates new shipping methods' do
          expect { subject }.to change { Spree::ShippingMethod.count }.by 4
        end
      end
    end

    context 'no rates are found' do
      let(:package) do
        instance_double(Spree::Stock::Package, easypost_shipment: fake_shipment)
      end

      let(:fake_shipment) do
        double(EasyPost::Shipment, rates: [])
      end

      it { is_expected.to be_empty }

      it 'create no new shipping methods' do
        expect { subject }.to_not change { Spree::ShippingMethod.count }
      end
    end
  end
end

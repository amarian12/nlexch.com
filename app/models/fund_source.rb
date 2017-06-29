class FundSource < ActiveRecord::Base
  include Currencible

  attr_accessor :name

  paranoid

  belongs_to :member

  validates_presence_of :uid, :extra, :member

  def label
    if currency_obj.try :coin?
      "#{uid} (#{extra})"
    else
      [extra, "****#{uid[-4..-1]}"].join('#')
      #begin
      #  [I18n.t("banks.#{extra}"), "****#{uid[-4..-1]}"].join('#')
      #rescue
      #  [extra, "***" , uid].join('#')
      #end
    end
  end

  def as_json(options = {})
    super(options).merge({label: label})
  end
end

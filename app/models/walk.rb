class Walk < ApplicationRecord
  has_many :stations, dependent: :destroy

  validates_presence_of :name, :location, :description
end
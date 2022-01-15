class Category < ApplicationRecord
  has_and_belongs_to_many :products
  # DONE add subcategories. Each subcategory can only have one parent
  belongs_to :parent, class_name: "Category", foreign_key: :category_id, optional: :true

  
  # If the parent is deleted, all subcategories will be destroyed
  has_many :subcategories, class_name: "Category", dependent: :destroy
  
  #i think this is wrong
  scope :all_parents, -> {where(category_id: nil)}
  scope :all_subcategories, -> {where.not(category_id: nil)}
  
  #DONE validating name of category is unique (this will ensure same name category can't be created more than once hence will only have one parent)
  validates_uniqueness_of :name
end

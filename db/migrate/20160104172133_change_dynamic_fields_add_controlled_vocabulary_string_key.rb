class ChangeDynamicFieldsAddControlledVocabularyStringKey < ActiveRecord::Migration
  def change
    change_table :dynamic_fields do |t|
      t.remove :controlled_vocabulary
      t.string :controlled_vocabulary_string_key, null: true
    end
    
    add_index :dynamic_fields, :controlled_vocabulary_string_key, unique: true
  end
end
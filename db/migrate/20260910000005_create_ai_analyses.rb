class CreateAiAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :ai_analyses do |t|
      t.references :trade, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.integer :discipline_score
      t.string  :pattern_detected
      t.text    :feedback
      t.text    :reflection_question
      t.timestamps
    end
  end
end

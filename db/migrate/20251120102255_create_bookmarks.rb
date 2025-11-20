class CreateBookmarks < ActiveRecord::Migration[7.1]
  def change
    create_table :bookmarks do |t|
      t.text :comment
      t.references :movie, null: false, foreign_key: { on_delete: :restrict }
      t.references :list, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :bookmarks, [:movie_id, :list_id], unique: true
  end
end

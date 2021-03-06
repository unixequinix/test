# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '2.4'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

assets = %w( .svg .eot .woff .ttf welcome_admin.css admin.css cable.js chartkick.js customer.css customer.js layout.css application_pdf.css pdf.css)
Rails.application.config.assets.precompile += assets

specific = %w(specific/*)
Rails.application.config.assets.precompile += specific

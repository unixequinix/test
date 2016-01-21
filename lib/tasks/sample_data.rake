namespace :db do
  desc 'Fill database with sample data'
  task create_admin_access: :environment do
    puts '----------------------------------------'
    puts 'Creating admin access'
    puts '----------------------------------------'
    make_admins
  end

  desc 'Fill database with sample data'
  task populate: :environment do
    Faker::Config.locale = :es
    puts '----------------------------------------'
    puts 'Creating fake data'
    puts '----------------------------------------'
    make_events
    make_companies
    make_preevent_items
    make_preevent_products
    make_company_ticket_types
    make_tickets
    make_gtags
    make_customers
  end

  def make_admins
    puts "Create admins"
    puts "----------------------------------------"
    Admin.destroy_all
    Admin.create(email: 'admin@test.com', encrypted_password: Authentication::Encryptor.digest("password"))
  end

  def make_events
    puts "Create events"
    puts "----------------------------------------"
    Event.destroy_all
    YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", "events.yml")).each do |data|
      event = EventCreator.new(name: data['name'], location: data['location'], start_date: data['start_date'], end_date: data['end_date'], description: data['description'], currency: data['currency'], host_country: data['host_country'], support_email: data['support_email'], features: data['features'])
      event.save
    end
  end

  def make_tickets
    puts 'Create tickets'
    puts '----------------------------------------'
    Ticket.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'tickets.yml')).each do |data|
        ticket = Ticket.new(event_id: event.id, code: data['code'], company_ticket_type_id: data['company_ticket_type_id'])
        ticket.save!
      end
    end
  end

  def make_companies
    puts 'Create companies'
    puts '----------------------------------------'
    Company.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'companies.yml')).each do |data|
        company = Company.new(event_id: event.id, name: data['name'])
        company.save!
      end
    end
  end

  def make_preevent_items
    puts 'Create preevent items'
    puts '----------------------------------------'
    PreeventItem.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'preevent-items.yml')).each do |data|

        item = data['purchasable_type'].constantize.new(
          preevent_item_attributes: {
            event_id: event.id,
            name: data['name'],
            description: data['description'],
            min_purchasable: data['min_purchasable'],
            max_purchasable: data['max_purchasable'],
            price: data['price'],
            step: data['step']
          }
        )

        item.counter = data['counter'] if data['purchasable_type'] == 'Voucher'

        item.save!
      end
    end
  end

  def make_preevent_products
    puts 'Create preevent product items'
    puts '----------------------------------------'
    PreeventProduct.destroy_all
    PreeventProductItem.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'preevent-product-items.yml')).each do |data|

        product = PreeventProduct.create!(event_id: event.id, name: data['name'])
        product_item = PreeventProductItem.new(amount: data['amount'], preevent_product: product, preevent_item: PreeventItem.find(data['item']))
        product_item.save!
      end
    end
  end

  def make_company_ticket_types
    puts 'Create company ticket types'
    puts '----------------------------------------'
    CompanyTicketType.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'company_ticket_types.yml')).each do |data|

        ticket = CompanyTicketType.new(
          code: data['code'],
          name: data['name'],
          event_id: event.id,
          company_id: data['company_id'],
          preevent_product_id: data['product_id']
        )
        ticket.save!
      end
    end
  end

  def make_gtags
    puts 'Create gtags'
    puts '----------------------------------------'
    Gtag.destroy_all
    Event.all.each do |event|
      YAML.load_file(Rails.root.join("lib", "tasks", "sample_data", 'gtags.yml')).each do |data|
        gtag = Gtag.new(
          event_id: event.id,
          tag_serial_number: data['tag_serial_number'],
          tag_uid: data['tag_uid']
        )
        gtag.save!
      end
    end
  end

  def make_customers
    puts 'Create customers'
    puts '----------------------------------------'
    Customer.destroy_all
    Customer.create(
      email: 'customer@test.com',
      encrypted_password: Authentication::Encryptor.digest("password"),
      name: 'Alejandro',
      surname: 'González Núñez',
      confirmed_at: '2015-04-21 13:39:18.381529',
      agreed_on_registration: true,
      event_id: 1)
    Customer.create(
      email: 'customer2@test.com',
      encrypted_password: Authentication::Encryptor.digest("password"),
      name: 'Pedro',
      surname: 'De La Rosa',
      confirmed_at: '2015-04-21 13:39:18.381529',
      agreed_on_registration: true,
      event_id: 1)
  end

end

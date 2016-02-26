class AccessForm < CredentiableForm
  def save
    @access = Access.new(catalog_item_attributes: { name: name,
                                                   description: description,
                                                   step: step,
                                                   initial_amount: initial_amount,
                                                   max_purchasable: max_purchasable,
                                                   min_purchasable: min_purchasable,
                                                   event_id: event_id
                                                 }
                       )
    if valid?
      persist!
      true
    else
      false
    end
  end

  private

  def persist!
    @access.catalog_item.credential_type = CredentialType.new if create_credential_type
    @access.save
  end
end

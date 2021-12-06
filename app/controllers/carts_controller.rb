class CartsController < ApplicationController
  before_action :authenticate_user!
  
  def update
    product_id = params[:cart][:product_id]
    quantity = params[:cart][:quantity]

    current_order.add_product(product_id, quantity)
    
    redirect_to root_path, notice: 'Product added succesfully'
  end

  def show
    @order = current_order
  end

  def pay_with_paypal
    order = current_order
    # order = Order.find(params[:cart][:order_id])

    # price must be in cents
    price = order.total*100

    response = EXPRESS_GATEWAY.setup_purchase(
      price,
      ip: request.remote_ip,
      return_url: process_paypal_payment_cart_url, 
      cancel_return_url: root_url, 
      allow_guest_checkout: true, 
      currency: "USD"
    )

    payment_method = PaymentMethod.find_by(code: "PEC")
    Payment.create(
      order_id: order.id, 
      payment_method_id: payment_method.id,
      state: "processing",
      total: order.total,
      token: response.token
    )

    redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token)
  end

  def process_paypal_payment
    details = EXPRESS_GATEWAY.details_for(params[:token])
    express_purchase_options =
    {
      ip: request.remote_ip,
      token: params[:token],
      payer_id: details.payer_id,
      currency: "USD"
    }
    price = details.params["order_total"].to_d * 100

    response = EXPRESS_GATEWAY.purchase(price, express_purchase_options)
    if response.success?
      payment = Payment.find_by(token: response.token)
      order = payment.order
      # notice below these are apostrophes
      order.state = 'completed'
      payment.state = 'completed'
      # if one of the operations below fail it can be reverted; either they're all succesful or none is executed. Transactions are protective blocks where SQL statements are only permanent if they can all succeed as one atomic action.
      ActiveRecord::Base.transaction do
        order.save!
        payment.save!
      end
      redirect_to root_url, notice: "Compra exitosa"
    else
      redirect_to root_url, alert: "Hemos tenido problemas para procesar tu pago"
    end
  end
end
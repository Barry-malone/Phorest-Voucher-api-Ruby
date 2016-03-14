require 'sinatra'
require 'HTTParty'
require 'prawn'
require 'chronic'
require 'barby'
require 'barby/barcode/code_39'
require 'barby/outputter/png_outputter'

set :port, 8080
set :static, true
set :environment, :production

HTTParty::Basement.default_options.update(verify: false)
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
get '/' do

erb :index

end

get '/vouchercreated' do


@@voucher_val = params[:voucher_val]
@@user_email = params[:user_email]

auth = {:username => "user/test@phorest.com", :password => "Testtest1"}

@req = HTTParty.get("https://eu-api.phorest.com/memento/rest/business/3Evn8Qqw6pVY4iScdZXWBA/voucher/branch/nPpLa0UY4UO5dn68TpPsiA/voucherserialnumber", :basic_auth => auth)



@built_voucher = @req.insert(95, "<issueDate>2016-03-12</issueDate><expiryDate>2016-07-12</expiryDate><originalBalance></originalBalance><creatingBranchRef>urn:x-memento:Branch:nPpLa0UY4UO5dn68TpPsiA</creatingBranchRef>")
@add_voucher_val = @built_voucher.insert(180, "#{@@voucher_val}")

@post_vouch = HTTParty.post("https://eu-api.phorest.com/memento/rest/business/3Evn8Qqw6pVY4iScdZXWBA/voucher",
              { 
               :body => "#{@built_voucher}" ,
               :basic_auth => auth ,
               :headers => { 'Content-Type' => 'application/vnd.memento.Voucher+xml' }
                })

@@serial_number = @req.scan(/\b\d{5}\b/).to_s.delete('[]""')

erb :voucher_created

end 

get '/voucher_pdf' do 

barcode_value = "#{@@serial_number}"

barcode = Barby::Code39.new(barcode_value)
File.open("voucher.png", 'w') { |f| f.write barcode.to_png(:margin => 3, :xdim => 2, :height => 55) }


content_type 'application/pdf'
@purchase_date = Time.now

 pdf = Prawn::Document.new
 pdf.font "Helvetica"
 pdf.text "Your Voucher Serial number: #{@@serial_number}", :align => :center
 pdf.move_down 10
 pdf.text "Voucher Value: €#{@@voucher_val}.00", :align => :center
 pdf.move_down 10
 pdf.text "Purchase Date:  #{@purchase_date}", :align => :center
 pdf.move_down 20
 pdf.text "A copy of this voucher has also been emailed to #{@@user_email}", :align => :center
 pdf.move_down 10
 pdf.image "voucher.png", :position => :center, :vposition => :center, :width => 200
 pdf.render


end 
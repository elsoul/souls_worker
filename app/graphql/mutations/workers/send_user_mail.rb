module Mutations
  module Workers
    class SendUserMail < BaseMutation
      description "Mail を送信します。"
      field :response, String, null: false

      argument :text, String, required: true
      argument :user_id, Integer, required: true

      def resolve(args)
        user = User.find(args[:user_id])
        html = ERB.new(" #{user.username} 様<br> #{args[:text]} ")
        mail = SendGrid::Mail.new
        mail.from = Email.new(email: "no-reply@yourmail.com")
        mail.subject = "申込みありがとうございます☻"
        personalization = Personalization.new
        personalization.add_to(Email.new(email: retailer.email, name: "申込者"))
        personalization.add_bcc(Email.new(email: ENV["ADMIN_EMAIL"], name: "管理者"))
        mail.add_personalization(personalization)
        mail.add_content(Content.new(type: "text/html", value: html.result))
        sg = SendGrid::API.new(api_key: ENV["SENDGRID"] || "")
        response = sg.client.mail._("send").post(request_body: mail.to_json)
        response.status_code
        { response: "Job done!" }
      rescue StandardError => e
        GraphQL::ExecutionError.new(e.to_s)
      end
    end
  end
end

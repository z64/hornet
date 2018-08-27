@[Discord::Plugin::Options]
class Hornet::PagedMessage
  include Discord::Plugin

  record Page, content : String, embed : Discord::Embed?

  class Controller
    getter channel_id
    getter user_id
    property! message_id

    def initialize(@channel_id : UInt64 | Discord::Snowflake,
                   @user_id : UInt64 | Discord::Snowflake,
                   @message_id : UInt64 | Discord::Snowflake? = nil,
                   &@block : Int32 -> Page?)
      @index = 0
      @pages = Array(Page).new
    end

    def next_page
      if page = @pages[@index]?
        @index += 1
        page
      else
        if page = @block.call(@index)
          @index += 1
          @pages << page
          page
        end
      end
    end

    def previous_page
      @index -= 1
      @index = 0 if @index < 0
      @pages[@index]? || next_page
    end
  end

  getter controllers

  def initialize
    @controllers = Deque(Controller).new
  end

  MAX_CONTROLLERS     = 50
  NEXT_PAGE_EMOJI     = "\u{27a1}"
  PREVIOUS_PAGE_EMOJI = "\u{2b05}"

  @[Discord::Handler(event: :message_reaction_add)]
  def handle(payload)
    controller = controllers.find do |c|
      c.message_id == payload.message_id &&
        c.channel_id == payload.channel_id &&
        c.user_id == payload.user_id
    end

    if controller
      case payload.emoji.name
      when NEXT_PAGE_EMOJI
        updated_page = controller.next_page
      when PREVIOUS_PAGE_EMOJI
        updated_page = controller.previous_page
      else
        # ignore
      end

      if updated_page
        client.edit_message(
          controller.channel_id,
          controller.message_id,
          updated_page.content,
          updated_page.embed)
      end
    end
  end

  def register_controller(channel_id : UInt64 | Discord::Snowflake,
                          user_id : UInt64 | Discord::Snowflake,
                          &block : Int32 -> Page?)
    controller = Controller.new(channel_id, user_id, &block)
    first_page = controller.next_page.not_nil!
    host_message = client.create_message(channel_id,
      first_page.content,
      first_page.embed)
    controller.message_id = host_message.id

    client.create_reaction(channel_id, host_message.id, NEXT_PAGE_EMOJI)
    client.create_reaction(channel_id, host_message.id, PREVIOUS_PAGE_EMOJI)

    @controllers.push(controller)
    @controllers.pop if @controllers.size > MAX_CONTROLLERS
    controller
  end
end

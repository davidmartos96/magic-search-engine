describe "multiverse ids" do
  include_context "db"

  # Old multipart cards have separate ID
  # New multipart cards have one ID
  # At some point mtgjson started ignoring separate IDs
  it "there are no duplicates" do
    # It's somewhat questionable when it comes to multipart
    # They have multiple ids
    by_id = db.printings.select(&:multiverseid).group_by(&:multiverseid).select{|k,v| v.size > 1}
    by_id.each do |id, cards|
      main_fronts = cards.map{|c| PhysicalCard.for(c).main_front}.uniq
      if main_fronts.size == 1
        # OK
      elsif cards[0].name == "Nalathni Dragon"
        # Known issue, ignore for now
      elsif cards[0].name == "Spined Wurm"
        # Known issue, ignore for now - PMEI / S00
      elsif cards[0].name == "Village Watch"
        # mtgjson bug
      else
        cards.size.should eq(1), "#{id} #{cards}"
      end
    end
  end
end

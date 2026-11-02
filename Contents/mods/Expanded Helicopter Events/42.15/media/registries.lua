local tags = {"ehe:signal_flare", "ehe:flare", "ehe:heli_part_metal", "ehe:supply_box"}
for _,tag in pairs(tags) do
    if not ItemTag.get(ResourceLocation.of(tag)) then
        ItemTag.register(tag)
    end
end

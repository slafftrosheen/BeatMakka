-- Explicit Studio MCP contracts; injected storage is not cloud rejoin evidence.
return function()
    local currentCheck = "room prerequisites"
    local function expect(value, message)
        assert(value, message or currentCheck)
    end
    local shared = game.ReplicatedStorage.Shared
    local server = game.ServerScriptService.Server
    expect(shared:FindFirstChild("RoomCatalog"), "Personal room catalog is not implemented")
    local Catalog = require(shared.RoomCatalog)
    local Profiles = require(server.ProfileStore)
    local Builder = require(server.RoomBuilder)
    local Rooms = require(server.RoomService)
    local checks = {}
    local function check(name, run)
        currentCheck = name
        run()
        table.insert(checks, name)
    end
    local function profile()
        return Profiles.new()
    end
    check("malformed and locked saved cosmetics fall back without granting progress", function()
        local p = profile()
        local value = Catalog.sanitize({ finish = {}, sign = "<script>", decor = "vinyl" }, p)
        expect(value.finish == "quay" and value.sign == "records" and value.decor == "none")
        expect(next(p.unlocked) == nil)
        p.unlocked.I01 = true
        expect(
            Catalog.sanitize({ finish = "coral", sign = "beats", decor = "vinyl" }, p).decor
                == "vinyl"
        )
        expect(not Catalog.allowed(p, "owner", 999))
        expect(not Catalog.allowed(p, "decor", {}))
    end)
    check(
        "legacy profiles gain defaults; storage round trip keeps independent finish and room",
        function()
            local p = profile()
            p.saveMode = "cloud"
            local data = { schema = 1, finish = "chalk" }
            local store = {
                GetAsync = function()
                    return data
                end,
                UpdateAsync = function(_, _, transform)
                    data = transform(data)
                    return data
                end,
            }
            Profiles.load({ UserId = 111 }, p, store)
            expect(p.room.finish == "quay" and p.finish == "chalk")
            p.unlocked.I01 = true
            p.room = { finish = "coral", sign = "beats", decor = "vinyl" }
            p.editVersion += 1
            expect(Profiles.save({ UserId = 111 }, p, store))
            local restored = profile()
            restored.saveMode = "cloud"
            Profiles.load({ UserId = 111 }, restored, store)
            expect(restored.room.finish == "coral" and restored.room.decor == "vinyl")
            expect(restored.room.sign == "beats" and restored.finish == "chalk")
            expect(data.schema == 2 and data.revision == 1)
        end
    )
    check(
        "failed writes retain room; restoring music preserves unsaved room and dirty state",
        function()
            local p = profile()
            expect(Profiles.save({ UserId = 112 }, p))
            p.room.finish = "afterhours"
            p.editVersion += 1
            expect(Profiles.restore(p))
            expect(p.room.finish == "afterhours" and p.editVersion ~= p.savedEditVersion)
            p.saveMode = "cloud"
            local ok = Profiles.save({ UserId = 112 }, p, {
                UpdateAsync = function()
                    error("offline")
                end,
            })
            expect(not ok and p.room.finish == "afterhours" and p.saved.room.finish == "quay")
        end
    )
    local fixture = Instance.new("Folder")
    fixture.Name = "RoomContractFixture"
    fixture.Parent = workspace
    local ok, err = pcall(function()
        local bays = Builder.build(fixture)
        for _, bay in bays do
            expect(
                bay.model:GetAttribute("StationId") == nil,
                "Room masquerades as a sampler and intercepts DeviceAppearance"
            )
            expect(
                bay.model:GetAttribute("RoomStationId") == bay.stationId,
                "Room association missing"
            )
        end
        local near = true
        local service = Rooms.new(bays, function()
            return near
        end)
        local a, b, c =
            { UserId = 101, DisplayName = "Owner A" },
            { UserId = 102, DisplayName = "Owner B" },
            { UserId = 103, DisplayName = "Visitor" }
        local pa, pb, pc = profile(), profile(), profile()
        check("two owned bays and overflow visitor; no client can name a foreign target", function()
            expect(service:assign(a, pa) and service:assign(b, pb))
            expect(not service:assign(c, pc))
            expect(service:summary(c, pc).id == nil)
            expect(not service:change(c, pc, "finish", "coral"))
            expect(not service:change(a, pa, "Room_2", "coral"))
            expect(not service:change(a, pa, "decor", "vinyl"))
            expect(service:change(a, pa, "finish", "coral"))
            expect(pb.room.finish == "quay" and pa.room.finish == "coral")
            near = false
            expect(not service:change(a, pa, "sign", "beats"))
            near = true
        end)
        check("progress unlock is separate; server visuals and disconnect are isolated", function()
            pa.unlocked.I01 = true
            expect(service:change(a, pa, "decor", "vinyl"))
            local own = bays[service:summary(a, pa).id]
            expect(own.model:GetAttribute("OwnerUserId") == a.UserId)
            expect(own.model:GetAttribute("Decor") == "vinyl")
            local crate = own.decor:FindFirstChild("H03")
            expect(crate ~= nil, "Unlocked crate was not constructed")
            for _, object in crate:GetDescendants() do
                if object:IsA("BasePart") then
                    expect(
                        object.Anchored
                            and not object.CanCollide
                            and not object.CanQuery
                            and not object.CanTouch,
                        "Decor affects physics/query"
                    )
                    expect(object.Position.Y - object.Size.Y / 2 >= 11, "Crate below safe shelf")
                    expect(
                        object.Position.Z - object.Size.Z / 2 >= 8.79,
                        "Crate outside rear mount"
                    )
                end
            end
            local oldB = service:summary(b, pb).id
            service:remove(a)
            expect(service:summary(b, pb).id == oldB)
            expect(
                own.model:GetAttribute("OwnerUserId") == nil
                    and own.model:GetAttribute("Decor") == "none"
            )
            expect(service:assign(c, pc))
            expect(own.model:GetAttribute("OwnerUserId") == c.UserId)
            expect(service:summary(c, pc).choices.finish == "quay")
        end)
        check("only compatible imported room art borrows authored maps", function()
            local bay = bays[service:summary(b, pb).id]
            local asset = bay.shelf
            local art = Instance.new("MeshPart")
            art.Name = "Art"
            art.Parent = asset
            asset:SetAttribute("TextureLayout", "incompatible")
            asset:SetAttribute("TextureResolution", 512)
            expect(service:change(b, pb, "finish", "chalk"))
            expect(
                art:FindFirstChildOfClass("SurfaceAppearance") == nil,
                "Incompatible UV layout was painted"
            )
            asset:SetAttribute("TextureLayout", require(shared.CosmeticCatalog).TextureLayout)
            expect(service:change(b, pb, "finish", "afterhours"))
            local surface = art:FindFirstChildOfClass("SurfaceAppearance")
            expect(surface ~= nil, "Compatible art did not receive authored maps")
            expect(
                surface.ColorMapContent.Uri
                    == "rbxassetid://"
                        .. require(shared.ContentIds).Images["atlas.afterhours.basecolor.512"],
                "Wrong room atlas"
            )
            expect(
                game.ReplicatedStorage.AppearanceLibrary.afterhours_512.Parent ~= nil,
                "Borrowed template removed"
            )
            art:Destroy()
        end)
        check(
            "fixed decor stays above controls; cosmetic geometry cannot affect navigation",
            function()
                for _, bay in bays do
                    for _, object in bay.model:GetDescendants() do
                        if object:IsA("BasePart") then
                            expect(
                                object.Anchored
                                    and not object.CanCollide
                                    and not object.CanQuery
                                    and not object.CanTouch
                            )
                            expect(object.Position.Y - object.Size.Y / 2 >= 7, object:GetFullName())
                            expect(
                                object.Position.Z - object.Size.Z / 2 >= 8.8,
                                object:GetFullName()
                            )
                        end
                    end
                end
            end
        )
    end)
    fixture:Destroy()
    expect(ok, err)
    return { passed = true, count = #checks, checks = checks, storage = "injected/session only" }
end

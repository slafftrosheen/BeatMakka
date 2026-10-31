> Current source/model revision: [28 October artbook refresh](COMPANION_ARTBOOK_REFRESH_2026-10-28.md). The supplied v1 artbook is the design reference; earlier rendered books and ZIPs describe pre-refresh candidates.

# Issue 20 — handoff разработчика

Base SHA: 8e8b91f6a5472eb6200599e60932e45a8c9ea56b. Изменения текущего batch остаются локальными. GitHub issue не закрывается по наличию кода или рендеров.

## Контракт и сеть

CompanionCatalog определяет только none/alissia/nikolas. Старые schema 1/2 загружаются с Alone и включёнными ненавязчивыми подсказками. Additive optional поле companion содержит selected и hints; schema и storage revision остаются прежними. Неизвестные/неверно типизированные значения безопасно приводятся к defaults при загрузке, а сетевые неизвестные ID отвергаются.

MusicNetwork.Command принимает CompanionSelect(id), CompanionHints(boolean), CompanionHint(). Команды маршрутизируются до station ownership gate и используют отдельный limiter, не расходуя бюджет Stop/Release. Сервер берёт профиль только из player, переданного OnServerEvent; extra payload, чужой ID, координаты, rewards, sample IDs и quest flags не принимаются. CompanionProgress — чистая read-only проекция. Клиент не завершает задания.

## Сохранение

Выбор меняет editVersion и использует существующую progressNeedsSave/drainQuestSave очередь. Если snapshot уже записывается, новый выбор остаётся в актуальном профиле и ставится в следующую запись; успешный старый snapshot не переписывает новое preference. Существующий UpdateAsync revision conflict сохраняется. При unavailable cloud выбор остаётся временным; UI не обещает постоянное сохранение.

Restore восстанавливает слоты и сохраняет текущий выбор спутника, как текущие discoveries/quests/shelf. Различие companion preference относительно сохранённого snapshot удерживает dirty-state. Реакции на save/discovery возникают из фактического server-owned изменения; restore-реакция появляется только при успешном Profiles.restore.

## Матрица активного прогресса

| Активный путь | Подсказка | Авторитетное действие |
|---|---|---|
| Q00–Q02 / P1 | Тори, ящики, звук причала, **четыре разных шага** | QuayDemoService и QuayProgress |
| Q03 | Публичное выступление добровольно; progression не блокируется | Существующий optional path |
| Q04–Q05 / P2 | Иво, безопасная цепочка ремонта, разные A/B, shelf/save | Существующая repair sequence и saved evidence |
| Q06–Q08 / P3 | Сначала Listen, затем роль звука; сохранить и убрать cases | Существующие sort/save/case handlers |
| Q09–Q10 / P4 | Mica, четыре равномерные доли; **1/5/9/13 только на третьем уровне** | QuayProgress reply и signal check |
| Q11–Q12 | Ronan, сохранённый материал и **шесть фаз** | ChapterConcert, без вмешательства follower |
| Legacy metal_pulse | **Два** разных шага, не четыре | NeighborhoodMissions после save |
| Legacy vent_duet/helper_reply | Два слоя / два разных chirp rhythms | Существующие legacy checks |
| Legacy FirstPerformanceQuest | Действительная текущая objective | Существующий courtyard performance |

Эфемерный server-owned companionRoute переключается валидными взаимодействиями Quay или legacy Mica/discovery, не клиентским выбором пути. При появлении/respawn в demo выбирается Quay. Награды и завершённость проекции не изменяют. Текущий валидный stop/парковка имеет приоритет над общей очередью заданий. Новый context сбрасывает градацию hints до первого уровня. Точные действия/ответы появляются только по повторному запросу.

## UI и follower

Выбор встроен третьей вкладкой в существующий журнал, с отдельным коротким shortcut рядом с картой. Нет второй самостоятельной модальной навигации. Hints можно скрыть. Alone полностью доступен. Effects OFF убирает декоративные движения, оставляя информацию и перемещение.

CompanionLibrary содержит импортированные локальные candidate-модели; выбранный экземпляр создаётся только в LocalPlayer workspace. Все части anchored, non-colliding, CanTouch=false, CanQuery=false. Движение обновляется на Heartbeat 20 Hz, независимо от музыкального clock. Есть grounding raycast, обход простого препятствия, snap после большой дистанции, reset при смене character root. При отсутствии земли/streaming-модели follower скрывается; он не платформа.

Follower скрывается при station editing, listening, Stage, ChapterConcert, Jam и открытом журнале. Он не создаёт звук и не забирает focus. Смена выбора и teardown используют generation token: завершившаяся старая async-сборка уничтожается. Ошибка атласа/модели не запускает retry каждый frame. Высокоуровневые source actions и локальные процедурные позы не объявляются опубликованными Animation assets.

## Сборка и нерешённые gates

Сначала tools/build_companion_candidates.py в Blender; затем package_local_demo_content.py и installer текущей Studio. Экспорт сохраняет исходные NPC, H04 и их IDs. CompanionModels — отдельный generated catalog. LocalArtLibrary импортирует новые модели с ArtApproved=false. Демо зависит от companion content и остаётся локальным.

Точные результаты source format/selene/Rojo и ограниченной Studio-инспекции сохраняются в docs/evidence/issue-20-companions. Новые test suites не добавляются и не запускаются. Cloud conflict, schema1/2 migration fixtures, phone/gamepad/мультиплеер и полный solo route требуют самостоятельной приёмки; исходный код не является доказательством их прохождения. Production manifest и итоговый отчёт отмечают реальный stage каждой сущности.

Итог batch и точные границы наблюдений: docs/ISSUE_20_IMPLEMENTATION_2026-10-26.md и docs/evidence/issue-20-companions/runtime-summary.json.


## Продолжение / предоставленный пакет / 26.10.2026

Исходный v1 сохранён без изменений под assets/references/companions/provided-pack-v1 с provenance.json. Его anchor-патчер рассчитан на старую a4a309b и не запускался. Поля profile.companion остаются текущей таблицей selected/hints, а не заменяются строкой из старого пакета.

CompanionJournal — новая чистая read-only проекция. Alissia получает три страницы по unlocked.I01/I02/I03. Nikolas читает только profile.saved.shelf: максимум разных metal-шагов, наличие metal+vent в одном audible pattern, число разных chirp masks. Все muted pads игнорируются. Она не вызывает Missions.awarded, не меняет profile, pattern, rewards, save или playback.

CompanionService добавляет journal в собственный State.companion. Кэш инвалидируется по selected, валидному stop, discovery flags и ссылке на новый успешный saved snapshot. Сканирование shelf не выполняется каждый музыкальный тик. Разговоры из двух реплик привязаны к текущему stop; legacy courtyard имеет отдельный текст. Клиент только меняет видимую страницу/реплику, новых RemoteEvents и команд нет.

CompanionPortrait загружает один локальный atlas и клон импортированной модели в ViewportFrame/WorldModel. При закрытии журнала, смене вкладки/выбора и teardown освобождает ресурсы. Generation token уничтожает устаревший результат async load. Камера карточки не меняет world camera; frame loop отсутствует. Follower остаётся единственным персонажем workspace.

Point/save/restore gestures ожидают закрытия интерфейса, а не истекают во время чтения. Исправлено направление X-поворота поднятой руки и колена с учётом локального front=-Z. Effects OFF сохраняет неподвижную информационную карточку и текст; декоративные жесты остаются выключенными.

Новые source/build/static receipts: docs/evidence/issue-20-pack-continuation. Старые runtime receipts относятся к предыдущему source snapshot и не являются автоматическим acceptance новой версии. Новый development ZIP — source/art handoff для существующего repository, не blind patch. Отдельный NeedleQuay-Companions.zip содержит локальное запускаемое демо.

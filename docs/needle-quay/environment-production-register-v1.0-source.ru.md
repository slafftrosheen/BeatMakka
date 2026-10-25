Подготовила production register v1.0 для Needle Quay — первого демо-района BeatMakka. Это основа отдельного артбука окружения: с конкретными зданиями, персонажами, квестами, архитектурными формами, материалами и списком графики для создания.

Главное решение: мы не создаём набор независимых красивых зданий. Каждое значимое сооружение должно иметь место в истории, понятную функцию и визуальную связь с музыкальным прогрессом игрока.

BEATMAKKA / NEEDLE QUAY

# Environment Production Register

Версия 1.0 · Основа для Environment & Quest Artbook

Design baseline

## 13

Зданий

## 4+1

Стоянки / клуб

## 7

Ключевых NPC

## 60+

Графических элементов

## 1. Визуальная идентичность района

[Zak Storm : Color Keys :: Behance](https://images.openai.com/static-rsc-4/EO0VYaRp3Q9Rn1UoejpYguwYUQuhiye26Zw3q9Ta7QLpMfNirLdrJTOhr4BK5xUkNFcWiD39KRuXzfSf7wlDIdf6aRac0xgNNET_kGpvQpvgBaUZNLsGtrNbqtG-aoc5P845ZeM1H4FQYi0gT753Qxg1dzrhHBbhO-RTLBIHpkQ?purpose=inline)

[Select 18 - Hong Kong antique shop by To Binh Binh for QClay on Dribbble](https://images.openai.com/static-rsc-4/2Tm1EiZjgex5XmzEG5jbMG4lQlPT5r0k9-0bLp_IohIk7c0lVxDIEKa3WtKBon3QA43R-S2z3pD81nvzKwG1dInpWUEoGJjaLf6GpR6kqywQU1sV_Wd8QDE4hLqJ79IKLU0m7b4MI3IdS9i9zlMfRTTCXorDWhV9yADBvX_v6-w?purpose=inline)

[Dead End: Stylized Environment Exploration Part 1](https://images.openai.com/static-rsc-4/b-tAHsFCuY6B5frueyqbmWKkzIQItje5QCbur7Yr6r1E9ZjQ6PrF3Ard88RUT4-qpOKuJY1ZY7PmTnxQiEjHvkfMIulM_L8k2mTyLqCO5qIkGXtG-sca_7PJeoOa2HgGATTEnPFz-LrxfPLJXbiw4QxHFVbqJF5Nz5VCv9Iw_Js?purpose=inline)

14

Это референсы визуального направления, не готовые модели и не утверждённые ассеты BeatMakka.

Архитектура Needle Quay должна выглядеть так, будто район строился постепенно: старый кирпич и деревянные доки, затем металлические мастерские, маленькие магазины и округлые ретрофутуристические надстройки. Все формы крупные, мягко скруглённые, немного асимметричные. Цвета — выцветший teal, cream, walnut wood, dusty coral и тёплый amber.

Важный принцип: район выглядит забытым, но не разрушенным. После прохождения квестов меняются свет, вывески, звуковая среда, активность NPC и небольшие детали — не требуется заменять здания целиком.

## 2. Каталог зданий

Размеры ниже — предлагаемые ориентиры для первого blockout в Roblox Studio, Ш × Г × В, в studs. Это не существующие измерения моделей в репозитории.

### Hero buildings — пять главных объектов

[Cadenza: Music, Betrayal and Death Collector's Edition · 스팀](https://images.openai.com/static-rsc-4/6RwCs1ozgmhJxXXBA7IW0FB6t20Yc8k1z5bbTL2uDbSfAuN3R7QquElvkE-PFQUS9kEB79YWduwI9cVCKWwz7-jyIxpredwOq8L-9EaU7I-p2qDNZNdkJP2XICaQ7HuMTZmuq-HuholA2Wr98i2aIoGWpSzuSUUeBxZ0zMcf8Eo?purpose=inline)

NQ-BLD-01 — The Lantern Room

44 × 30 × 26 · Финальная локация · P0

Бывший центр музыкальной жизни района. Скруглённый входной портал, старая вывеска с латунными буквами, большие закрытые окна, боковой служебный вход.

NPC: Ronan Wren, Хранитель Паузы. Квест: финальный концерт, восстановление сцены и символическое возвращение района к жизни.

Модель: полноценный фасад, входной вестибюль, компактный зал и сценическая зона. Две световые конфигурации: до и после финала.

[The Ultimate Guide to Record Store Day: Unleashing Vinyl Magic – Quetzal Studio](https://images.openai.com/static-rsc-4/X0gCsUo76frrTEeilDBiDLuWacUvLsrvwZJKXIA8pJlZNvbHg0zk2O0VWyMbhuortv5PMnNMsGQ7iTm92D37PVJ0_EnjK4IOeuil4K7XzPXDQ9Kz92bohFgVarCxJyYQHt800_JFmHdRHFBtzVc0XEAOf_x3aFqriIodoe697Nw?purpose=inline)

NQ-BLD-02 — Needle Records

24 × 18 × 19 · Магазин винила · P0

Небольшой двухэтажный магазин с выцветшей виниловой вывеской, ящиками пластинок и навесом. Место хранения музыкальной памяти района.

NPC: Naya, архивистка. Квест: классификация музыкальных элементов, поиск потерянных историй и сохранение первого осмысленного паттерна.

Модель: фасад, витрина, компактный доступный торговый зал. Важно: использовать уже существующий канонический объект H06, а не создавать второй несовместимый магазин.

[Furkii's Stylized Workshop - 3D model by alperademkotan \[863ae6a\] - Sketchfab](https://images.openai.com/static-rsc-4/OZwNx0umqohM1pnMY-1PcXj-9k8Xij8Le9EJIp2_VNCuesbeuLlqsAC6s26RZCUDkzZMQY3kGGudsnqUxeY4xQyOlZAxxfJXP75nHLGKhoUEha0JWcbbYKcgVmy_QTe0oKA_bk9DXT1DKQDp-eg6fo_qDVhLaOEuXBX_q-Fj2Ig?purpose=inline)

NQ-BLD-03 — Morrow Repairs

32 × 24 × 19 · Мастерская · P0

Мастерская со сдвижной дверью, большими вентиляционными решётками, стойкой инструментов и механическими деталями. Её архитектура должна буквально намекать на ритм.

NPC: Ivo, механик и звуковой экспериментатор. Квест: восстановить вентиляционный механизм, открыть `I02 vent_thump`, научиться создавать вариации A/B.

Модель: фасад, передняя рабочая зона и один функциональный механизм. Остальные помещения — декоративные.

[\[WIP\] Overwatch 'Dorado' Map Environment — polycount](https://images.openai.com/static-rsc-4/bIl2xxF3iiVCROTrbKi16l6lKQObekoUCSkVKtGZ9yKEBMCuuucOwvql5GChrFdoDpgTh8B4EuTWQw7kODl33Nl-SCRTj6pnrjrxlms6ZHNr4PIHESp-Ja3ded_ZUn0gjfvaC9W9-tESB6F5j027mSxBGuA0R5JpuDnWuqR8lqg?purpose=inline)

NQ-BLD-04 — Harbor Market Hall

48 × 30 × 16 · Рынок · P0

Полуоткрытый крытый рынок с несколькими цветными навесами, центральным проходом и маленькой площадкой для выступлений. Важный центр общественной жизни.

NPC: Sana Bell, координатор рынка; Naya появляется здесь по квесту. Квест: восстановление торговых мест, сортировка предметов, подготовка пространства к музыкальному событию.

Модель: полностью проходимый первый уровень, 4 модульных прилавка, закрытые технические помещения.

[The Desert Station - DAE Villages - 3D model by Magnus Isdahl (@Isdahl) \[9d3379e\] - Sketchfab](https://images.openai.com/static-rsc-4/lc4c2GAzGZJvYIqer_As5CHEYwYeX6nuXo7nFbN7WruruF5LYNMaVvPN-oCye1pYB-NVVEa1UOeYG3WnN_d0rwmTu2PDbZzWzG-CAoA7ysBQV0HdpJmbSRMhsUy0-wEntwFJ8JhsBsRb40HcKmI4_f_NXwV2AVFNiN-ej1mVOUg?purpose=inline)

NQ-BLD-05 — Signal House

16 × 16 × 26 · Радиоузел · P0

Старый радиопередатчик на волнорезе. Приземистый домик, высокая антенна, круглое сигнальное окно и кабели, встроенные в архитектуру.

NPC: Mica, робот-помощник. Квест: восстановить локальный музыкальный сигнал, открыть `I03 robot_chirp` и подготовить связь с The Lantern Room.

Модель: экстерьер, один доступный пульт, анимация антенны и сигнального света. Полный интерьер не нужен.

### Supporting buildings — восемь зданий окружения

| ID        | Название                | Примерный размер | Назначение                                                          |
| --------- | ----------------------- | ---------------- | ------------------------------------------------------------------- |
| NQ-BLD-06 | Warm Current Café       | 18×16×13         | Кафе Nell Fen; слухи, короткие разговоры, уютная точка отдыха       |
| NQ-BLD-07 | North Slip Ferry Office | 18×12×11         | Билетная касса, навигация, атмосферная деталь порта                 |
| NQ-BLD-08 | Quay Supply & Tackle    | 16×12×10         | Магазин снастей и мелкого инвентаря; подводка к доковым заданиям    |
| NQ-BLD-09 | Cinder Cold Storage     | 34×20×16         | Старый холодильный склад; трубопроводы и индустриальные звуки       |
| NQ-BLD-10 | Quayside Flats          | 38×16×26         | Жилой дом с магазинами внизу; формирует читаемый силуэт квартала    |
| NQ-BLD-11 | Tidewash Laundry        | 18×16×14         | Прачечная; декоративное вращение машин и ритмический фон            |
| NQ-BLD-12 | Relay Substation        | 12×12×11         | Подстанция, визуально связанная с восстановлением сигнала           |
| NQ-BLD-13 | Dockline Depot          | 30×22×20         | Портовый склад и место для повторяемых модулей ящиков, дверей, рамп |

Для демо у этих зданий не должно быть полноценных интерьеров. Достаточно фасадов, хорошо оформленных окон, одного-двух коротких взаимодействий возле входа и аккуратной постановки улиц.

Дополнительно нужны четыре общих набора окружения: модульные склады, жилые фасады, портовые конструкции и дальний силуэт набережной. Они собираются из общих деталей, а не моделируются как десятки уникальных зданий.

## 3. Четыре стоянки: здания, NPC и квесты

Эти имена уже существуют в World Artbook v2, поэтому оставляем их основными. Новые названия из предыдущего обсуждения можно использовать как названия отдельных точек внутри локаций, а не заменять ими карту.

[Dead End: Stylized Environment Exploration Part 1](https://images.openai.com/static-rsc-4/b-tAHsFCuY6B5frueyqbmWKkzIQItje5QCbur7Yr6r1E9ZjQ6PrF3Ard88RUT4-qpOKuJY1ZY7PmTnxQiEjHvkfMIulM_L8k2mTyLqCO5qIkGXtG-sca_7PJeoOa2HgGATTEnPFz-LrxfPLJXbiw4QxHFVbqJF5Nz5VCv9Iw_Js?purpose=inline)

NQ-STOP-01 · Dockside Exchange

Здания: Quay Supply & Tackle, Dockline Depot. NPC: Tori, доковый мастер.

Игрок помогает подготовить заброшенную площадку, находит `I01 metal_hit`, собирает первый четырёхшаговый ритм и даёт маленькое выступление.

Обязательные ассеты: пирс, доковые стойки, цепи, 2 уровня ящиков, складской фонарь, концертная зона фургона.

[Hello Neighbor 2 Alpha 1 в Steam](https://images.openai.com/static-rsc-4/r2yJr3p9PP3aXq2v9DcvZ70Oem7AS3aueXWsSOLmblN91JAFutwK5fDhjKzzs6zUMt9Q9EbHS9ErfOrd7_vwuv7pZoCQYdMOqymgoNDkBHb1DnFtbe5y16G-wo0fVKcrEoSDBzrJQi1mGdOwVC0AiZJXECgqKiIcKHdIwpYQ8ks?purpose=inline)

NQ-STOP-02 · Repair Alley

Здания: Morrow Repairs, Cinder Cold Storage. NPC: Ivo.

Игрок чинит вентиляцию, сравнивает реальные звуковые паттерны и учится создавать музыкальную вариацию вместо бесконечного повторения.

Ассеты: вращающаяся вентиляция, лампы неисправности, металлические крышки, трубы, кабель-каналы.

[Drive Discs - Zenless Zone Zero Wiki - Mobalytics](https://images.openai.com/static-rsc-4/ixyzoZwARerUJatMBXyh2QtGysl4yXUZaVgFcDVYfveDuFb7gIYhXSlzd5A1ZwdwlmdrOnppDcr9yQhheVIgGbIWTykDidAsh-G1rBmbY6XlqjFa4ysYJMGywmfL3JqX7xZY-Sk_x9-3mXoYi4GCg4oVtw3r5Zn9huRY3c0QKk8?purpose=inline)

NQ-STOP-03 · Vinyl Market

Здания: Needle Records, Harbor Market Hall. NPC: Naya и Sana.

Игрок сортирует музыкальные материалы, различает beat/bass/melody, узнаёт историю закрытого клуба и сохраняет музыку в Beat Shelf. Здесь можно впервые услышать намёк на Trip Hop из соседнего района, не открывая его досрочно.

Ассеты: ящики винила, стойки, обложки, маленькие афиши, маркировка музыкальных категорий.

[Big Walk: All Radio Station Locations](https://images.openai.com/static-rsc-4/4eG7wxjU8LcfRwTLAtMZbwPSOeH9Bn-8FM0o2guFVXgnHkfqmdzSk3r4p85DVK9pyV3K_9zZ_MiI30USZMdLjw1RxVUWS0gkmw8Jf1Pf0gd-YqM0zRxdZHX9Os6DUfgJAmJxZB9u3vQXEGuX2bs_hMX-nlp19lruYHENeWTbmrI?purpose=inline)

NQ-STOP-04 · Breakwater Steps

Здания: Signal House, Relay Substation. NPC: Mica.

Игрок собирает звук робота `I03 robot_chirp`, создаёт музыкальный ответ на заданный ритм и включает локальный передатчик. Свет вдоль набережной постепенно возвращается.

Ассеты: каменные ступени, радиомачта, распределительный щит, сигнальные фонари, кабельный маршрут.

Финальная точка — The Lantern Room. После четырёх стоянок игрок попадает в уже предусмотренный шестистадийный концертный сценарий. Ronan Wren не враг: он разуверился в том, что музыке здесь ещё есть место. Игрок возвращает людям возможность снова создавать что-то вместе.

## 4. Реестр NPC

| Персонаж   | Где появляется        | Характер и функция                                             | Визуальный силуэт                                         |
| ---------- | --------------------- | -------------------------------------------------------------- | --------------------------------------------------------- |
| Tori       | Dockside Exchange     | Практичный доковый мастер. Учит находить ритм в обычной работе | Широкий жилет, rolled-up sleeves, пояс инструментов       |
| Ivo        | Morrow Repairs        | Увлечённый механик, слышащий музыку в устройствах              | Высокий худощавый силуэт, рабочая куртка, защитные очки   |
| Naya       | Needle Records        | Хранительница истории музыки района                            | Объёмный свитер, яркая сумка с пластинками                |
| Sana Bell  | Harbor Market Hall    | Организатор, которая объединяет жителей                        | Крупная сумка, планшет заказов, тёплые коралловые акценты |
| Mica       | Фургон и Signal House | Уже существующий робот-помощник, проводник игрока              | Сохраняем текущий канонический дизайн                     |
| Ronan Wren | The Lantern Room      | Хранитель Паузы, финальный собеседник                          | Длинное пальто, ключи, приглушённые тона, усталая осанка  |
| Nell Fen   | Warm Current Café     | Добрая хозяйка кафе, сообщает о жизни квартала                 | Фартук, объёмный силуэт, кружка и заметки                 |

Имена Tori, Ivo, Naya и Mica сохраняют связи из World Artbook v2. Ronan Wren, Sana Bell и Nell Fen предлагаются для фиксации в этой версии. Никакого переименования Mica в Mika.

Важно, чтобы NPC знали друг друга: Tori отправляет игрока к Ivo, Naya рассказывает о Ronan, Sana готовит посетителей, а Mica соединяет музыкальные открытия с восстановлением городского сигнала.

## 5. Квестовый production register

| ID     | Квест                 | NPC / место          | Результат                                     |
| ------ | --------------------- | -------------------- | --------------------------------------------- |
| NQ-Q00 | The Van Arrives       | Mica, первая стоянка | Знакомство с фургоном-студией                 |
| NQ-Q01 | Make Room for Music   | Tori, пирс           | Расчистить площадку                           |
| NQ-Q02 | Rhythm in the Metal   | Tori                 | Открыть I01, собрать 4-step beat              |
| NQ-Q03 | First Dockside Jam    | Tori                 | Первое необязательное публичное выступление   |
| NQ-Q04 | The Vent Has a Pulse  | Ivo                  | Починить вентиляцию, открыть I02              |
| NQ-Q05 | One Beat, Two Ways    | Ivo                  | Создать две вариации паттерна                 |
| NQ-Q06 | Records Remember      | Naya                 | Разобрать и сопоставить музыкальные материалы |
| NQ-Q07 | Keep Your Sound       | Naya                 | Сохранить композицию в Beat Shelf             |
| NQ-Q08 | Market Is Listening   | Sana                 | Подготовить рынок к концерту                  |
| NQ-Q09 | Signal, Not Noise     | Mica                 | Открыть I03 и решить ритмическую задачу       |
| NQ-Q10 | Light the Breakwater  | Mica                 | Включить локальный радиосигнал                |
| NQ-Q11 | Open the Lantern Room | Ronan                | Разговор и подготовка сцены                   |
| NQ-Q12 | The Quay Plays Again  | Ronan и жители       | Финальный концерт и оживление района          |

Квесты должны сохранять прогресс персонально. Другие игроки могут помочь или присутствовать на выступлениях, но число зрителей и популярность не являются условиями завершения. Ни один квест не зависит от недоступной функции записи микрофона Roblox.

## 6. Материалы и текстуры

[Peeling Paint Seamless Texture](https://images.openai.com/static-rsc-4/-XJ7OpoNjwvfGPYM5A_7CggzpoUdCKbajPryerWvkladLsYzO_owaGO2tMkbieoU9gAcpBB9xfDgBNvK16gSmHVCjq3C9kpIcorqVhs5HYtjwbY6dRCFnIjPs1EjCt_97hhxaLJDPmxjz49rASEbgw-PA-tdhVVGuyqk7brZ1ZIQzliAwlaIiDgeAR3MFpL9?purpose=inline)

MAT-01 — Faded Teal Metal

Мастерские, фонари, транспорт, дверные панели

[of Weathered Painted Wood Planks with Peeli… PBR Texture | AITextured](https://images.openai.com/static-rsc-4/UQ7HJLwuVteJJ8ZDVVq_sCGtD3nXpsgmii7OKPsxd9obb0Hof2FLSNj3r6nIIc1rCSQT6p3n-CwdYUQv4QG7JzKG3bKfpehmcwgCQ6SRuBuN6kayx7NxpP1XNr6tHjbwQkJ45ltZeZyab000PpKQ7CLrxiYvq8IArAAt3x3A1ms?purpose=inline)

MAT-02 — Cream Painted Trim

Карнизы, оконные рамы, вывески

[Fine Walnut Wood PBR Texture – Seamless Hardwood Material](https://images.openai.com/static-rsc-4/dlNcbKACDlonr4tSIWcihikj2cvP9MWFdBMCWEFsfmFX_mXkARRn5tTR4fITVPMtw_kpzmJhk5-oes6H06bLQ5MMqaP_fZoTgVwJ0nXtRJH6pmJOMl1LpnckkGcauq_m_HGUWu0wPVBXjGbuYEGuC9xzIRnf7cJNc3mVuzLDsU0?purpose=inline)

MAT-03 — Warm Walnut

Виниловые ящики, двери, стойки

[Tragark Village - Environmental Design Evolution: Some Tileable Texture Progress](https://images.openai.com/static-rsc-4/0seK77SBCU4eXa5Lz4-f74_pvLTlQdo0It4kFIPF0ikFrJKJBb_dxByVk1lOCY6HsZKpcj6dIUdEqmOjHVHDet1BX4af6rBKA2NI9YKwDUAm91N7PraedlXERy5DO8eSBXcevYo-WcQTCVfklMa-5F5PLdlUNjPNB0EHpG-TCbo?purpose=inline)

MAT-04 — Dock Timber

Пирсы, настилы, грузовые площадки

[Cracked Brick Wall with Warm Earthy Tones PBR Texture – Seamless Material](https://images.openai.com/static-rsc-4/vrcidBjMdqIKHHiA8qRzZXU7kTbUiWJZS0hb26HF8v9qBPWyuT2Z491XjhFDr7GMAaOwv-g_DBCrY_MZgu8OBqhQxjncckDQaipBecllPHbzFDoy9-8kIDywe2kyl6TSZcR3nZ1VZoTJnUfEZs7d-aR9AWtccOo0DleaKSD4Yzg?purpose=inline)

MAT-05 — Sea-Worn Brick

Клуб, склады, дома

[Stylized Textures – Vol 56 – Concrete - 3D Texture by oleekconder](https://images.openai.com/static-rsc-4/Xtok9F0m64cnsYBg6IpbHSlfHSqCNSSFOX1ZQ5cgNuonrwx-M7nbFg1NqrnjXeUf2WmDTDBKXvRCvUdW8aygWAmZFIKP2tMjtx2lxCPvZOpHzAZ1IhzjiYT6oi3wOkiiDOZaPgpMeSER0D12w-snzlDJHEevzIqxYy-DkcTDq2M?purpose=inline)

MAT-06 — Quay Concrete

Волнорез, стены, лестницы

Дополнительные семейства в реестре:

| ID     | Материал           | Использование                            |
| ------ | ------------------ | ---------------------------------------- |
| MAT-07 | Dusty Coral Enamel | Акцентные таблички, корпуса оборудования |
| MAT-08 | Dark Cast Iron     | Опоры, трубы, перила                     |
| MAT-09 | Oxidized Brass     | Ручки, старое сценическое оборудование   |
| MAT-10 | Amber Glass        | Фонари, окна с тёплым свечением          |
| MAT-11 | Canvas & Awning    | Навесы рынка и фургона                   |
| MAT-12 | Graphite Rubber    | Шины, кабели, технические накладки       |

Это каталог материальных семейств, а не требование изготовить 12 независимых тяжёлых PBR-наборов. Сначала нужно сопоставить их с существующим `FZ_MaterialAtlas_v1`, использовать его оттенки и повторное применение, а затем создавать только действительно отсутствующие текстуры.

## 7. Графические ассеты: вывески, постеры, граффити, декали

### Вывески

[Joel Holland expresses his love for London via charming illustrations of shopfronts | Creative Boom](https://images.openai.com/static-rsc-4/vLzAEXhgd40TucLfyhOruahYaDU19wx0cSDBZrFWHYRh_3-kzl1cLMErAAAuv0avANRacPOWu6D-U9T5kOQcKBSsUxUOhumC36b6ffMvmwowrajW9yCHOsFH21Ckn3ZtNNCPp1SkShSsFrQWx7mjvrCTrbdnS9nr8LtsVeOmisI?purpose=inline)

[Discover 62 Sign Paint Reference and lettering ideas | lettering fonts, painted signs, hand lettering and more](https://images.openai.com/static-rsc-4/4Y_Qt9it-eDOVixIJTbkhiJSwWmN-hgG04fDr8sC56pcWwjgJyvOvffHGmuqLDhuO5EvJoq34UU7y7miTrcS1ghPahivTXl9nB-eqLRYGZpL2ArUQm3PxJokXv9xerOrHCt9nUcmDZ35TFoGxh0AcdVg2EkiVv7KNWpFGRhwDuQ?purpose=inline)

[Caroline's Milwaukee: An Intimate Jazz Club Experience in Walker's Point](https://images.openai.com/static-rsc-4/57uGeiVGxk1fZk2QF_3SuigxFC56oo1WeqWy7U4YTm4L7sjjUYJSyOrSgpuJagZgtUwHbXccJ1muoxjGf5ZpXEJLJ4VLWsWPg-9hVItNDWCK36o2l3OTL90cbGYFiosDtOHH4lKfdqFpEUxHXWhWaOgTW1pw8jKWf90QGuyERrc?purpose=inline)

13

Создать семейство из 13 основных вывесок — по одной для каждого здания, включая единый стиль шрифтов и иерархии. Пять главных вывесок должны получить индивидуальную композицию, остальные могут использовать общие корпуса, рамки и крепления.

В графической библиотеке нужны отдельно:

- `NQ-SGN-01…05` — пять уникальных hero-знаков;
- `NQ-SGN-06…13` — восемь небольших вывесок поддержки;
- `NQ-WAY-01…06` — стрелки набережной, рынка, клуба, мастерской, стоянок и радиодома.

### Постеры

[Adam Racubah and Friends | Yr Heulyn Y Felinheli Sat 02 May 2026](https://images.openai.com/static-rsc-4/M5H9chhaAZPITtTWUBQMbASnz5GNr_l9_Rb9vAncODukU8S1i00ahobIWpMLEwdN-ZB7wnKsisBYT5w2wRAZTZnGC1Z6ZfA7oZWKKJO3KiKCjOMOwadYp9oPB3Go84bivdvznLJGvnftMOK-UiEyalv0lWJcmHCDPvpwsE_UzWs?purpose=inline)

POST-01 / Lantern Room — старый концерт

[Feria de Vinilo Garage | Centro Gabriela             Mistral](https://images.openai.com/static-rsc-4/BFIj7tGhOH7v9IIjbS5GOZHgimYPCWn5I1qyONJJi1DJiBIHCho0DVla0MIDGwo1LoMTNmP2FnkPWtOaoO6uHvp_uKJCllLkPhWbxXJm0ONJR29wVXTRryiZILOKGZsA4YV4Wmcq76Xp1f1tjJs2OJZ7lIFoagYYbyijafZvirg?purpose=inline)

POST-02 / Vinyl Swap — рынок

[Visit Østfold Hvaler Fix It 2026 -](https://images.openai.com/static-rsc-4/s29wXZhKBLTrhwVeR8pPWHwOfpim5zUQ71cyEI31yM7BnUzyVMOyvvmLi2qifktZhEWtUHGFeyN0I5Sgsa-9cSJ9zyFnxOQHvuBz2iVm1sZrguQTlIMskxWBGQWOeQfLoy1ImKsBAx-lR6CEa-ppjGwu8NFoMsBhrZIIyyMtJg0?purpose=inline)

POST-03 / Repair Day — мастерская

[Stream harbor fest 2024 by treble | Listen online for free on SoundCloud](https://images.openai.com/static-rsc-4/ZYBceJaeBE1MQwoiXelnZ0Knkx-f01b7fnvuwEAbdR84uYWxmPihr-CH65Qd5S74KUqufUoGoivX8hfzN7lA4pCuuaZU32LbPVrug2hh_ulKauxSEOB8y7AlnVvnQG0qhjNcGZgyBUWDbeueGN74ErFnP2--4YEZU-jy_E4ds7M?purpose=inline)

POST-04 / Quay Sessions — районный фестиваль

Всего нужно 8 оригинальных постеров: четыре представленных направления плюс Radio Broadcast Night, Dockworkers Jam, Community Market Day и Lost Frequencies. Для некоторых понадобятся выцветшая и новая версии.

### Граффити и уличная графика

[Joe Nelson Murals and Street Art | FindMASA](https://images.openai.com/static-rsc-4/B6L-P9EopmT2MnsZ_sEBF8Uc3sd-u4gOAyYai-b4J0mrY2iFTva4ROzu94imxm2dgzxMJeKVx8aW7A-6KX9rxLJNkk_N6LgmPNQRiIGnA-iyePNAprI6S7ZD3D-EagCe2QsKvBHEYUsXLC0zUjwFaTr2a3BNIoEpHJpeng_IvOY?purpose=inline)

[LL One-Day Special: The Murals of Chapel Hill](https://images.openai.com/static-rsc-4/UN_d1UFoVdWgFKPHbb_6BRlS022sfS_aqWdqzjAoUKyEX2-1hT-k-WSWCzJoXEV-BZEU0O6KAqHyqBx-0WQqhqGNkB-qdtxm1Z6DqrfYCpchCJ6hjt6-QXLrMJc2H1c-JEU6gcqD-MYJuBWvalbSFX0cpFX7dmc0uBu-KMZiTGg?purpose=inline)

[Boosting Brand Identity: Leggetts Sand Bar Mural Magic](https://images.openai.com/static-rsc-4/ZEjdQX8ArALNMqoImK0Ibdh-bYgrCfPx7TK2SagzNC1yD9MHxYqFqUwwV2SiKNVLznkaykSFGg40qcPT0IbdrWV6sFgfvMsArIYyhWjre4yCe2y38fxcuRVKhj5EhWxZ7hAaoXkPV-yJ1tfUKYKRkSJ_zso64ORQfuYLNeij18M?purpose=inline)

11

Создать 10 авторских граффити как отдельные прозрачные изображения:

| ID     | Графика                                  | Место                          |
| ------ | ---------------------------------------- | ------------------------------ |
| GRA-01 | RUST CAN SING                            | Доковые склады                 |
| GRA-02 | ONE MORE SONG                            | Подход к клубу                 |
| GRA-03 | KEEP THE QUAY PLAYING                    | Главная уличная стена          |
| GRA-04 | LOW TIDE / HIGH NOTES                    | Набережная                     |
| GRA-05 | Звуковая волна, переходящая в волну моря | Волнорез                       |
| GRA-06 | Абстрактный робот-помощник               | Около Signal House             |
| GRA-07 | Руки, передающие друг другу винил        | У рынка                        |
| GRA-08 | Старый символ радиочастоты               | Техническая аллея              |
| GRA-09 | Миниатюрные музыкальные наклейки и теги  | Витрины, урны, ящики           |
| GRA-10 | Большой мурал об истории квартала        | Стена рядом с The Lantern Room |

Разные граффити должны ощущаться сделанными разными жителями. Но цветовая палитра, форма линий и плотность деталей остаются контролируемыми. Никаких реальных логотипов, узнаваемых обложек музыкальных альбомов или чужих авторских персонажей.

### Служебные декали и мелкая графика

Нужны ещё 24–30 небольших декалей: номера причалов, жёлто-кремовая разметка парковки, указатели загрузки, электропредупреждения, инвентарные номера, наклейки на усилители, товарные этикетки, радиошкалы, стикеры фургона и маркировка квестовых взаимодействий.

Их лучше выпустить не хаотично, а тематическими пакетами: `NQ-DOCK`, `NQ-WORKSHOP`, `NQ-MUSIC`, `NQ-SIGNAL`, `NQ-COMMUNITY`.

## 8. Что художник должен подготовить для каждого здания

Обязательная карточка здания — NQ-BLD-XX

Изометрический цветной mock в общей стилистике

Ортографические виды спереди, сбоку и сверху

Габаритный blockout в studs

Схема модульных деталей и точек повторного использования

Material IDs и расположение графики на фасаде

Места NPC, входов, интерактивных объектов и звуков

Состояние Before/After восстановления

Оптимизационные заметки: коллизии, LOD, повторное использование

Исходник 3D, экспорт для Studio и превью на нейтральном фоне

4 из 9 пунктов готовы

&#x20;Скопировать чек-лист

Для Roblox реализация должна учитывать актуальные рекомендации Creator Hub. Повторяемые поверхности лучше оформлять через `MaterialVariant`, специфические UV-текстуры MeshPart — через `SurfaceAppearance`; современные PBR-карты включают albedo, normal, roughness, metalness и emissive. Основная оптимизация достигается переиспользованием meshes/текстур, разумными разрешениями, streaming и проверкой реальных draw calls.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://create.roblox.com\&sz=32)

Documentation - Roblox Creator Hub

+2



Рабочие размеры: 512×512 для большинства поверхностей, 1024×1024 только там, где это оправдано видимой крупной детализацией; мелким декалям часто хватит 128–256 пикселей. Это ориентиры, а не обязательные размеры каждого ассета.&#x20;

[image](https://www.google.com/s2/favicons?domain=https://create.roblox.com\&sz=32)

Documentation - Roblox Creator Hub

+1



## 9. Порядок производства

01

Blockout и улицы

Сначала размещаются 13 простых объёмов зданий, 4 стоянки, клуб, дорожная сеть и фургон. Проверяются расстояния, видимость ориентиров и отсутствие тупиков.

02

Пять hero concept sheets

Полные виды главных зданий, схема доступа, связь с NPC, расположение интерактивных элементов.

03

Модульные окружения и NPC

Фасады, крыши, окна, уличный реквизит, семь согласованных силуэтов персонажей.

04

Texture & Graphic Bible

Материалы, граффити, афиши, вывески, логотипы заведений, декали, шаблоны экспорта.

05

Artbook и игровая проверка

Собрать всё в отдельный визуальный артбук, затем убедиться, что каждый квест реально связан с геометрией, освещением и состоянием мира.

Итоговый отдельный артбук я бы назвала BeatMakka — Needle Quay: Buildings, Characters & Street Art, Vol. 01.

Он должен включать не только красивые изометрические рендеры, но и полноценные листы моделирования, карты размещения, NPC, состояния до/после восстановления, готовую графику и точные реестры ассетов. Пока это утверждаемая концептуальная спецификация: изображения выше — визуальные ориентиры, а не произведённые и загруженные в репозиторий модели.

Следующим производственным шагом считаю создание первых пяти hero building sheets, начиная с The Lantern Room и Needle Records. Эти два здания зададут архитектурный язык всего района, после чего остальные можно будет делать намного быстрее и последовательнее.
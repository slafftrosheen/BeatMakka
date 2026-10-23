# BeatMakka / MK-I - Device Artbook - Alpha 01

Русская редакция, 23 октября 2026. Дизайн-предложение. Не runtime acceptance.

## Файлы

- PDF: BeatMakka_MK-I_Artbook_Alpha01_RU.pdf
- Интерактивный прототип: MK-I_Prototype.html
- Верстка: build_artbook.py
- Токены: design-tokens.json

## Полный текст разворотов

### 01 / Обложка

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

ALPHA 01 / DEVICE DESIGN STUDY

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

01

MK-I

Собери свой ритм.

УСТРОЙСТВО / ЭКРАНЫ / УПРАВЛЕНИЕ

BEATMAKKA / ALPHA 01

Русская редакция / дизайн-предложение v1.0

### 02 / Играть. Услышать. Сделать своим.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

01 / PRODUCT PROMISE

Играть. Услышать. Сделать своим.

Один музыкальный инструмент, который хочется открыть ещё раз. Мир начинается с собственного ритма.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

02

Тактильный снаружи.

Точный внутри.

Тёплый корпус принадлежит мастерской Needle

Quay. Цифровой экран помогает сочинять:

большие пэды, понятные состояния, короткий путь

от удара до сохранённого бита.

01 / Руки остаются на месте

Сетка 4×4 неподвижна. Жест игры не превращается в прокрутку.

02 / Музыка отвечает сразу

Удар, выбранный пэд и записанная нота имеют различимые состояния.

03 / Свой результат остаётся своим

Паттерны и сохранённый бит не теряются при переходах между экранами.

ПРЕДЛОЖЕНИЕ / НА ОСНОВЕ ОБСУЖДЕНИЯ

### 03 / Что является опорой дизайна

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

02 / SOURCES & BOUNDARIES

Что является опорой дизайна

Новая визуальная редакция развивает устройство из исходного артбука. Она не заменяет реестр и не продвигает стадии готовности ассетов.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

03

Основа

Что сохраняем

Что проектируем здесь

Артбук v0.2 / board

Тёплая палитра, ремонт, материальность

Иерархия цифрового экрана и новая композиция UI

H01 / authored contract

6×1.25×4 studs; 16 пэдов; -Z

Наглядный top view и смысл органов управления

Код на 6ed1b00

16 шагов; 60-180 BPM; A-D; shelf ×6

Статичные экраны и touch-first flow

Alpha 01 / issues #1-19

Инструмент раньше расширения мира

Порядок UI, звука, кастомизации и концерта

Roblox / acceptance

Честные IDs и permissions

Отдельная приёмка, не показанная как готовая функция

Статусы в книге

ЕСТЬ В КОДЕ - существующая логика. ALPHA 01 - предлагаемый дизайн. ПОЗЖЕ - исследование или следующий этап.

### 04 / Учимся устройствам, не копируем их

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

03 / MANUFACTURER RESEARCH

Учимся устройствам, не копируем их

Просмотрены официальные страницы и руководства Akai, Ableton, Novation и Elektron. Ниже - выводы для нашего продукта, а не сравнительный

обзор рынка.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

04

AKAI / MPC

Главный режим даёт контекст; редактирование открывается явно.

В MK-I: статус и транспорт постоянны, сложное действие имеет отдельный

экран.

R1, R2 / OFFICIAL MANUAL

ABLETON / MOVE

Короткая навигация и понятный возврат из браузера.

В MK-I: Preview отдельно от Assign; Back возвращает в предыдущий

контекст.

R3 / OFFICIAL MANUAL

NOVATION / CIRCUIT

Паттерн имеет различимые выбранное и ожидающее состояния.

В MK-I: слот виден текстом; будущую очередь не выдаём за готовую

функцию.

R4 / OFFICIAL MANUAL

ELEKTRON / DIGITAKT II

Контекст меняется, расположение параметров остаётся

узнаваемым.

В MK-I: заголовок всегда объясняет, какой пэд или паттерн редактируется.

R5 / OFFICIAL MANUAL

### 05 / Что берём. Во что превращаем.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

04 / TRANSLATION, NOT IMITATION

Что берём. Во что превращаем.

Аппаратные органы управления у производителей физические. В игре шестнадцать пэдов тоже должны помещаться в touch-интерфейсе.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

05

Принцип

Наша адаптация

Сознательно упрощаем

Стабильный Main

PLAY / STEPS / SOUNDS / BEATS

Не переносим desktop DAW на телефон

Явные режимы

Один экран - одна задача

Нет обязательных Shift-комбинаций

Контекстный редактор

PAD 01 / KICK виден в каждом действии

Нет десятков параметров одновременно

Браузер с возвратом

Preview → Assign → Back

Не подменяем звук от простого скролла

Статус музыкального времени

BPM, слот и transport на своих местах

Не обещаем hardware latency / velocity

Живой переход паттерна

Предложение для будущего live-режима

Alpha пока останавливает транспорт при выборе

Ссылки R1-R5 и границы заимствования - в конце книги.

### 06 / Корпус узнаваем. Контролы точны.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

05 / DEVICE ANATOMY

Корпус узнаваем. Контролы точны.

H01 / MK-I. Ортографическая схема задаёт количество и соответствие контролов; концепт-иллюстрация задаёт материал и характер.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

06

01

02

03

04

05

07

08

09

10

11

12

13

14

15

16

01 / цифровой экран

02 / master slider

03 / 2 энкодера

04 / 16 пэдов

6 W × 1.25 H × 4 D STUDS / PIVOT: BOTTOM CENTER / FRONT: -Z

### 07 / Вещь с историей, экран без шума.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

06 / MATERIAL LANGUAGE

Вещь с историей, экран без шума.

Повреждения живут на краях корпуса. Рабочие поверхности, надписи и зоны нажатия остаются чистыми и читаемыми.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

07

TEAL / краска

Сатиновая краска, спокойный общий силуэт.

CREAM / кант

Матовый защитный металл с точечным износом.

WALNUT / дерево

Крупный рисунок, тёплые боковины.

PAD / силикон

Мягкая поверхность, лёгкий внутренний свет.

LCD / стекло

Глубокий тёмный фон; никакой грязи поверх текста.

### 08 / Один инструмент. Четыре характера.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

07 / COSMETIC FAMILY

Один инструмент. Четыре характера.

Существующие finish IDs сохраняются. Цвет корпуса не меняет значения пэдов, раскладку, hit targets или результат записи.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

08

01

02

03

04

05

06

07

09

10

11

12

13

14

15

16

Workshop teal

quay

Warm cream

chalk

Repaired coral

coral

After hours

afterhours

Косметические пресеты используют совместимый общий atlas. Смена скина не маскирует selected, muted,

recording и unavailable; эти состояния имеют собственный текст и форму.

### 09 / Не заставлять пальцы целиться в 3D.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

08 / PHYSICAL-TO-DIGITAL MAP

Не заставлять пальцы целиться в 3D.

Модель приглашает подойти. Точная работа происходит в отдельном интерфейсе, где контролы достаточно крупные.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

09

01

02

03

04

05

06

07

08

10

11

12

13

14

15

16

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

Kick

SELECTED

Snare

2

Closed hat

3

Open hat

4

Clap

Q

Rim

W

Low tom

E

High tom

MUTED

Shaker

Tambourine

S

Bell

Pluck

F

Bass C

Z

Bass E-flat

X

Bass G

Chord

V

PLAY

STEPS

SOUNDS

BEATS

PAD 01 / KICK

Warm kick

YOUR LOOP / A

Tap a pad. Build something yours.

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

На корпусе

В UI

Рамка Alpha 01

Пэды / экран / transport

Сетка 01-16; контекст; Play/Rec/Stop

Позиции и номера соответствуют миру

Энкодеры / slider

Крупные цифровые поля / Sound control

Не все нарисованные ручки - реализованные параметры

### 10 / Тёплый свет. Строгая иерархия.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

09 / DIGITAL DESIGN SYSTEM

Тёплый свет. Строгая иерархия.

Цвет помогает, но никогда не является единственным носителем значения. Gameplay-текст остаётся native UI.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

10

INK

#162322

TEAL

#2F5C58

CREAM

#E8D8B7

AMBER

#F3B65F

CORAL

#CA7453

FADED

#6F9186

Сетка

Базовый шаг 8. Отступы 16 / 24 / 32. Радиусы 6-12 в UI; крупные рамки

мягче. Минимальная цель нажатия - авторский target 44 px.

Типографика

В игре: Gotham / GothamBold из текущей Theme. Цифры BPM и шага -

стабильной ширины. В PDF: Segoe UI и Consolas для качественного русского

экспорта.

AMBER FILL → INK TEXT / CORAL FILL → INK TEXT / INK FILL → CREAM TEXT

### 11 / Четыре основных экрана. Один инструмент.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

10 / NAVIGATION ARCHITECTURE

Четыре основных экрана. Один инструмент.

В performance-контексте пэды и транспорт закреплены. Библиотека и shelf открываются явным действием, а не случайным свайпом.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

11

PLAY

играть

STEPS

редактировать

SOUNDS

выбирать

BEATS

сохранять

Глобально

BPM, A-D, Play / Record / Stop, статус

сохранения.

Внутри режима

Выбранный пэд, редактор шагов или список с

отдельным Assign.

Отдельно

Look и Settings доступны без перегрузки

performance-панели.

Назад возвращает в предыдущий контекст. Прямой переход PLAY возвращает к инструменту за одно действие. Позиция списка

сохраняется; selected pad и музыкальные данные не сбрасываются.

### 12 / Главный экран - музыкальная поверхность.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

11 / PERFORMANCE SCREEN

Главный экран - музыкальная поверхность.

ALPHA 01 / основной вариант для планшета и desktop. Цифровое поле сообщает контекст, а не конкурирует с пэдами.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

12

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

PLAY

STEPS

SOUNDS

BEATS

PAD 01 / KICK

Warm kick

YOUR LOOP / A

Tap a pad. Build something yours.

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

### 13 / Та же память рук на любом экране.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

12 / RESPONSIVE COMPOSITION

Та же память рук на любом экране.

Меняем композицию, а не номера пэдов и значения действий. Мировая форма устройства не обязана съедать экран телефона.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

13

MK-I

96 BPM

A

B

C

D

READY

PAD 01 / WARM KICK

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

STOP

PLAY

REC

STEPS

SOUNDS

BEATS

QUAY SESSION

SESSION SAVE

EXIT

16 STEPS

PAD 01 / KICK

Warm kick

YOUR LOOP / A

Tap a pad. Build something yours.

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

Landscape: фиксированные пэды и транспорт; вторичный текст можно скрыть

### 14 / Один палец - один управляемый удар.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

13 / TOUCH CONTRACT

Один палец - один управляемый удар.

Предлагаемый input-контракт. Значения задержек и число одновременных касаний подтверждаются измерением, не картинкой.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

14

DOWN

Удар начинается по нажатию, не после

отпускания.

CAPTURE

Палец закреплён за первым пэдом до Up /

Cancel.

MULTITOUCH

Разные пальцы не отменяют и не переносят

чужой удар.

NO SCROLL

В пределах performance-grid отключён touch

pan.

CANCEL

Потеря фокуса и выход очищают активные

касания.

NO PRESSURE

Не обещаем velocity по силе касания без API и

устройства.

Свайп не «рисует» ноты по соседним пэдам. Hold-жесты не нужны для первого бита.

### 15 / Играть и записывать - разные состояния.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

14 / TRANSPORT & RECORDING

Играть и записывать - разные состояния.

Понятная надпись и форма важнее одного цветного огонька. Звуковой отклик и запись шага - разные операции.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

15

01

READY

Пэды звучат при нажатии. В паттерн

ничего не пишется.

02

PLAY

Паттерн крутится. Пэды можно

слушать поверх.

03

REC

Игровые удары добавляются в

ближайший шаг.

04

STOP

Останавливает транспорт.

Музыкальные данные остаются.

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

Kick

SELECTED

Snare

2

Closed hat

3

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

Bass G

16

Chord

V

STEPS

SOUNDS

BEATS

PAD 01 / KICK

Warm kick

YOUR LOOP / A

Tap a pad. Build something yours.

REC ON

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

Решение Alpha

Сохраняем существующее квантование 1/16 и 16 шагов. Count-in, undo

и изменение resolution - отдельные будущие функции.

REC обозначается текстом и отдельной формой. Reduced motion не

скрывает recording state.

### 16 / Сначала выбранный звук. Потом его шаги.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

15 / STEP EDITING

Сначала выбранный звук. Потом его шаги.

STEPS редактирует ровно один из 16 пэдов. Выбранный PAD, его звук и активный слот видны до любого изменения.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

16

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

Chord

V

PLAY

STEPS

SOUNDS

BEATS

PAD 01 / 16 STEPS

1/16

01  ON

02  OFF

03  OFF

04  OFF

05  ON

06  OFF

07  OFF

08  OFF

09  ON

10  OFF

11  OFF

12  OFF

13  ON

14  OFF

15  OFF

16  OFF

CLEAR PAD

MUTE PAD

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

Нажатие меняет ON/OFF.

Текущий playhead -

рамка/указатель, не замена

ON.

Mute сохраняет ноты.

Clear требует ясного

контекста.

На телефоне шаги 4×4 на

отдельном экране; PLAY

возвращает пэды.

### 17 / Слушать отдельно. Назначать осознанно.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

16 / SOUND BROWSER

Слушать отдельно. Назначать осознанно.

Прокручивается только список SOUNDS. Скролл и выделение файла не меняют звук в паттерне автоматически.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

17

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

PLAY

STEPS

SOUNDS

BEATS

ASSIGN TO PAD 01

01   Warm kick

02   Dry snare

03   Quay metal

COLLECTED

04   Vent thump

05   Helper chirp

PREVIEW

ASSIGN TO PAD

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

PAD 01 указан явно.

Preview не пишет в паттерн.

Assign - отдельное действие.

Locked объясняет, где найти

звук.

На телефоне библиотека -

отдельный экран с Back to

Play.

### 18 / Принести звук из района в свой бит.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

17 / DISCOVERY FLOW

Принести звук из района в свой бит.

Сбор виртуальных игровых звуков - текущая творческая основа. Это не обещание записи реального микрофона.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

18

01

Найти

I03 / helper robot: взаимодействие с

объектом.

02

Получить

Звук появляется в коллекции с

происхождением.

03

Назначить

Выбран PAD 01, Preview → Assign.

04

Использовать

Добавить шаг или записать удар.

Сохранить бит.

I01

QUAY METAL

metal_hit

I02

VENT THUMP

vent_thump

I03

HELPER CHIRP

robot_chirp

### 19 / A–D - четыре варианта одной идеи.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

18 / FOUR INDEPENDENT PATTERNS

A-D - четыре варианта одной идеи.

Каждый слот хранит собственные 16×16 шагов, назначения, mute и BPM. Полка сохраняет весь четырёхслотовый проект.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

19

A

96 BPM / ACTIVE

B

120 BPM / LOOP

C

140 BPM / LOOP

D

96 BPM / EMPTY

ЕСТЬ В КОДЕ

Выбор слота останавливает Play и Record. Сетка сразу показывает

выбранный паттерн. Данные остальных слотов не стираются.

ПОЗЖЕ / LIVE-QUEUE

Запуск следующего паттерна по границе такта - отдельная проектная

задача. Показывать QUEUED можно только после реализации протокола.

### 20 / Шесть мест. Каждый бит хранит A–D.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

19 / PERSONAL BEAT SHELF

Шесть мест. Каждый бит хранит A-D.

Фиксированные названия Beat 01-06 сохраняют понятность и не создают неготовую систему публичных имён.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

20

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

PLAY

STEPS

SOUNDS

BEATS

YOUR BEAT SHELF

Beat 01

4 PATTERNS / SAVED

Beat 02

EMPTY

Beat 03

Beat 04

Beat 05

Beat 06

SAVE TO SHELF

LOAD BEAT

Each beat stores all four patterns.

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

Выбор позиции сам ничего не

загружает.

Save captures все четыре

слота.

Load заменяет working slots,

не полку.

Версия shelf защищает от stale

overwrite.

Cloud и session save

обозначены явно.

### 21 / Ошибку можно заметить. Работу - сохранить.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

20 / SAVE & DESTRUCTIVE ACTIONS

Ошибку можно заметить. Работу - сохранить.

Диалоги используются только для действий с последствиями. Сохранение и редактирование имеют независимые состояния.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

21

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

PLAY

STEPS

SOUNDS

BEATS

YOUR BEAT SHELF

Beat 01

4 PATTERNS / SAVED

Beat 02

EMPTY

Beat 03

Beat 04

Beat 05

Beat 06

SAVE TO SHELF

LOAD BEAT

Each beat stores all four patterns.

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

LOAD BEAT 01?

Replaces all four working patterns.

Stops playback. Shelf stays unchanged.

CANCEL

CONFIRM LOAD

CONFIRMATION EXPIRES / 5s

OVERWRITE / LOAD

Повторное подтверждение действует 5

секунд. Изменение проекта или позиции

отменяет pending action.

FAILED SAVE

Правки остаются открытыми и dirty.

Никакой ложной надписи Saved.

BUSY

Load / Restore недоступны во время

сохранения. Статус объясняет ожидание.

### 22 / Первый бит без устного объяснения.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

21 / FIRST-BEAT STORYBOARD

Первый бит без устного объяснения.

Сценарий приёмки, а не обещание фиксированного времени. Новичок должен суметь повторить путь самостоятельно.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

22

01 / Открыть

Подойти к MK-I. Увидеть доступный

инструмент и понятный вход.

02 / Поиграть

Нажать несколько неподвижных пэдов.

Узнать характер звуков.

03 / Записать

Включить Record и сыграть простой ритм

или включить шаги.

04 / Вариация

Выбрать B, создать вторую идею. A

остаётся на месте.

05 / Сохранить

Beat 01 → Save to shelf. Увидеть точный

save status.

06 / Вернуться

Изменить рабочие слоты, подтвердить

Load и услышать сохранённый бит.

### 23 / Открывать глубину постепенно.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

22 / PAD DETAIL & COMPLEXITY

Открывать глубину постепенно.

Alpha 01 не превращает первый экран в студийный пульт. Дополнительные звуковые параметры проектируются отдельными этапами.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

23

Слой

Экран / управление

Статус

Игра

Hit / Select pad / Play / Record

Основной предлагаемый Alpha UX

Редактор

Assign sound / 16 steps / Mute / Clear

Существующие операции в новой композиции

Уровень звука

Sound on/off; явный master mute

Есть базовое управление; slider требует

реализации

Тембр / обработка

Gain, filter, envelopes, sends, automation

Позже: не выдавать ручки за рабочий DSP

Undo / duplicate / arranger

Безопасные музыкальные вариации

Отдельные предложения, вне обещаний текущего

кода

Физический энкодер может быть частью образа; игровая функция должна иметь отдельный контракт.

### 24 / Не заставлять угадывать по цвету.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

23 / STATUS LANGUAGE

Не заставлять угадывать по цвету.

Каждое состояние имеет текст, форму или второй признак. Одновременные selected / muted / hit не смешиваются в один цвет.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

24

01

READY

Тихий пэд; номер и имя видны.

02

SELECTED

Рамка / боковой маркер +

label.

03

HIT

Короткий световой отклик; без

тряски UI.

04

MUTED

MUTED + перечёркнутый

speaker marker.

05

RECORDING

REC + видимый transport state.

06

UNAVAILABLE

Причина: locked, loading или

no access.

Reduced motion: остаются текст, выбранная рамка и позиция playhead. Цветовое мерцание необязательно.

### 25 / Понятно на слух, видно глазами, удобно рукой.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

24 / SETTINGS & ACCESSIBILITY

Понятно на слух, видно глазами, удобно рукой.

Настройки открываются отдельно. Их изменение не стирает паттерны и не скрывает текущий музыкальный статус.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

25

Управление

Touch, keyboard и gamepad используют одни действия. Видимый focus;

Back не теряет контекст.

Доступность

Reduced motion; маркировка не только цветом; увеличение текста без

уменьшения пэдов ниже hit target.

Локализация

Короткие UI labels EN / RU / LV. Ширина с запасом; текст не запечён в

корпус или texture atlas.

Аудио

Mute отделён от Record. Загрузка/permissions не маскируются под тишину

выбранного звука.

### 26 / Мир зовёт. Устройство даёт контроль.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

25 / WORLD-TO-INSTRUMENT FLOW

Мир зовёт. Устройство даёт контроль.

Сначала проверяем владельца станции и дистанцию. Музыкальный интерфейс не требует сидеть на стуле или целиться в маленькие 3D-надписи.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

26

01

Подойти

Явный prompt и статус свободно /

занято.

02

Открыть

Fixed performance UI. Touch

movement не перекрывает пэды.

03

Создавать

Паттерн принадлежит игроку, а не

станку.

04

Выйти

Освободить station, остановить

запись, сохранить текущие правки в

сессии.

Уход со станции

Distance / death / respawn / disconnect очищают session ownership. Запись

не продолжается незаметно после закрытия.

Сохранение - отдельное действие

Working state остаётся с игроком в сессии. Cloud durability подтверждается

реальной save/rejoin-приёмкой, не видом экрана.

### 27 / Район узнаёт собственную музыку.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

26 / CHAPTER CONCERT CONCEPT

Район узнаёт собственную музыку.

ПОЗЖЕ / финал секции района. Это новый encounter, а не изменение условий уже работающего первого квеста Мики.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

27

MK-I

QUAY SESSION

SESSION SAVE

EXIT

A

B

C

D

96 BPM

16 STEPS

READY

01

Kick

SELECTED

02

Snare

2

03

Closed hat

3

04

Open hat

4

05

Clap

Q

06

Rim

W

07

Low tom

E

08

High tom

MUTED

09

Shaker

10

Tambourine

S

11

Bell

12

Pluck

F

13

Bass C

Z

14

Bass E-flat

X

15

Bass G

16

Chord

V

PLAY

STEPS

SOUNDS

BEATS

PAD 01 / KICK

Warm kick

YOUR LOOP / A

Tap a pad. Build something yours.

STOP

RECORD

SOUND ON

EFFECTS ON

SAVE *

MK-I / NEEDLE QUAY

LOOK   /   SETTINGS

Не popularity gate

NPC реагируют на понятные освоенные

приёмы. Для прохождения не нужна

аудитория реальных игроков.

Подсказка не перекрывает пэды

Один короткий музыкальный запрос в

цифровом поле. Успех постепенно

оживляет жителей, свет и вывески.

Своя композиция остаётся своей. Не требовать совпадения с единственным «правильным» треком.

### 28 / Два устройства. Одна музыкальная фраза.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

27 / FUTURE COOPERATIVE SET

Два устройства. Одна музыкальная фраза.

ПОЗЖЕ / Link-подобное ощущение, не обещание интеграции Ableton Link SDK или готовой пятичленной группы.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

28

01

02

03

04

05

06

07

08

09

10

11

12

13

14

15

16

96 BPM

BAR START

SHARED CLOCK

Сначала двое

Роли, темп, фаза, timestamped changes. Известные звуки воспроизводятся

локально.

До пяти - после измерений

Clock drift, jitter, сеть, voices и headroom требуют доказательства на

целевых устройствах.

### 29 / Тот же характер - в своём record shop.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

28 / PERSONAL SPACE & CUSTOMIZATION

Тот же характер - в своём record shop.

Косметика связывает инструмент с районом. Она не меняет музыкальные возможности и не вводит неутверждённую экономику.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

29

Материалы одной семьи

Те же дерево, краска, ткань и металл. Новые

варианты сохраняют совместимый atlas и

читаемость.

Личное и общее

Отделить владение магазином, декором и finish

устройства. Посетитель не редактирует чужие

настройки.

Исходный утверждённый board / визуальная опора, не новая приёмка отдельных моделей.

### 30 / Фиксированные Frames вместо длинного Canvas.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

29 / ROBLOX IMPLEMENTATION HANDOFF

Фиксированные Frames вместо длинного Canvas.

Предлагаемая компонентная структура. Книга и браузерный прототип не являются изменением production Luau.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

30

Компонент

Обязанность

Ограничение

InstrumentShell

Safe insets, layout, current view

Не скроллится; не перехватывает pad gestures

PadGrid16

Pointer ownership, selected/hit/muted

Exact 4×4; canonical 01-16; no on-release-only hits

ContextDisplay

Play / Steps / browser / shelf

Показывает selected pad, slot и operation target

TransportBar

Play / Record / Stop / sound

Стабильное место; не уничтожается при смене view

LibraryList

Samples / beats / длинные каталоги

Единственный явный scroll region

SaveState / Dialog

Dirty, busy, error, stale version

Server authority; clear user confirmation

UI не создаёт аудио IDs, cloud permissions или asset acceptance. Эти этапы остаются отдельными.

### 31 / Красота укладывается в существующий бюджет.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

30 / PRODUCTION CONTRACT

Красота укладывается в существующий бюджет.

Это authored project constraints, а не ограничения платформы. Никакая новая картинка не является лицензией на provider spend.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

31

Пакет / contract

Сохраняемый предел

Приёмка

H01 / assembled workstation

До 4500 triangles, включая 16 пэдов

Измерить полную сборку, а не одну оболочку

H01 / world envelope

6×1.25×4 studs / bottom-center / -Z

Сверить границы, pivots и station interaction

Texture family

1024 cap; shared 512 derivatives

UV/layout version, каналы, финальная PBR-проверка

U01-U04 / native UI

Текст и focus отдельно от bitmap

Touch, gamepad, keyboard, reduced motion

Stages

candidate → DCC-clean → art-approved

Потом Studio-imported → runtime-verified

Концепт-рендеры этой книги не отправляются как многообъектный provider input.

### 32 / Что уже есть. Что делаем следующим.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

31 / ALPHA 01 DELIVERY MAP

Что уже есть. Что делаем следующим.

Implementation evidence и design intent разделены. Главная приёмка - первый сохранённый и снова открытый бит.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

32

Слой

Статус

Связанные issues

A-D / shelf / first Mica quest

ЕСТЬ / проверено в Studio на 6ed1b00

#6 / сохранить поведение

Fixed UI / touch / navigation

ALPHA 01 / дизайн этой книги

#2, #3, #6

Настоящий звук / лицензии / cloud saves

ОТДЕЛЬНАЯ ПРИЁМКА

#4, #5, #10

Finish / record shop / final imports

P1 / визуальный и ownership review

#8, #9, #11

Район / concert finale

P1 / новый chapter encounter

#12, #13

Jam / MIDI / microphone

ПОЗЖЕ / исследование и измерения

#15, #16, #18, #19

### 33 / Принимать руками, глазами и сохранённым результатом.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

32 / ACCEPTANCE CHECKLIST

Принимать руками, глазами и сохранённым результатом.

Это чек-лист будущей implementation-приёмки. Проверка самого PDF не подтверждает поведение Roblox.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

33

TOUCH

16 пэдов видны. Несколько касаний не вызывают scroll, ghost hits и

зависание.

MUSIC

Play / Record / Stop и квантование объяснимы. Недоступный звук имеет

причину.

NAVIGATION

Back и PLAY возвращают без потери слота, selected pad и рабочего

проекта.

SAVE

Overwrite/load требуют подтверждения. Dirty/error/busy честны; rejoin

проверяется отдельно.

VISUAL

Материалы читаются нейтрально и на закате. В UI нет лишнего шума и

нечитаемых labels.

DEVICE

Реальный телефон/планшет, gamepad и keyboard проверены с

измерениями, а не обещаниями.

### 34 / Первичные источники. Датированные выводы.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

33 / SOURCES & RESEARCH RECEIPTS

Первичные источники. Датированные выводы.

Официальные материалы просмотрены 23.10.2026. UI-графика производителей не включена в книгу: схемы и экраны MK-I оригинальные.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

34

R1 / AKAI MPC 3 FAQ

Новый Main Mode; разделение режимов. Не переносим arranger и сложность целиком.

R2 / AKAI MPC 3.6 UI example

Просмотрены Main и отдельное modal editing; не копируем форму/графику.

R3 / ABLETON MOVE MANUAL

Browser / Back / audition. Переносим короткий путь, не hardware microphone или Link SDK.

R4 / NOVATION CIRCUIT TRACKS

Состояния паттернов и различие selection / queued transition.

R5 / ELEKTRON DIGITAKT II

Раздел 6, стр.18: стабильная contextual organization. Поисковая версия доступна; прямой PDF не выдал файл.

Клик по блоку открывает официальный источник. Полные URL и журнал доступны в SOURCE.md.

### 35 / Дизайн, который можно продолжить.

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

34 / SOURCE PACKAGE & REVIEW STATUS

Дизайн, который можно продолжить.

PDF + исходный код верстки + tokens + интерактивный браузерный прототип. Визуальный review не подменяет реализацию.

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

35

Авторские иллюстрации

Hero и material macro созданы imagegen по утверждённому board.

Ошибочный первый 12-pad вариант отклонён; в книге используется

исправленный 4×4 concept.

Детерминированные экраны

Все пэды, UI, схемы и номера собраны векторами. Концепт корпуса не

является геометрическим чертежом, texture atlas или art-approved asset.

Браузерный прототип

Оригинальные исходные WAV проекта; только локальная демонстрация

interaction. Не соединён с Roblox, облачной полкой, permissions или

микрофоном.

Следующее решение

Посмотреть performance-экран на реальном телефоне/планшете,

согласовать композицию и затем реализовать A01-01/A01-02. Никаких

скрытых uploads или spend.

ART DIRECTION v1.0 / APPROVAL PENDING / CANONICAL ASSET CONTRACTS UNCHANGED

### 36 / Обложка

BEATMAKKA / MK-I

DEVICE ARTBOOK / ALPHA 01 / 23.10.2026

MK-I / BEATMAKKA

DESIGN PROPOSAL / NOT A RUNTIME ACCEPTANCE

36

Музыка начинается

с одного удара.

Неподвижные пэды. Понятный экран. Твой район.

ALPHA 01 / MK-I DEVICE ARTBOOK / v1.0

## Полные ссылки на исследования

- R1 / AKAI MPC 3 FAQ: https://support.akaipro.com/en/support/solutions/articles/69000857771-mpc3-faq
  Новый Main Mode; разделение режимов. Не переносим arranger и сложность целиком.
- R2 / AKAI MPC 3.6 UI example: https://support.akaipro.com/en/support/solutions/articles/69000860746-akai-pro-mpc-series-changing-the-time-signature
  Просмотрены Main и отдельное modal editing; не копируем форму/графику.
- R3 / ABLETON MOVE MANUAL: https://www.ableton.com/en/move/manual/
  Browser / Back / audition. Переносим короткий путь, не hardware microphone или Link SDK.
- R4 / NOVATION CIRCUIT TRACKS: https://userguides.novationmusic.com/hc/en-gb/articles/26207128061458-Using-Circuit-Tracks-Synths-MIDI-Tracks-and-Drums
  Состояния паттернов и различие selection / queued transition.
- R5 / ELEKTRON DIGITAKT II: https://www.elektron.se/wp-content/uploads/2025/04/Digitakt-2-User-Manual_ENG_OS1.10A_250415.pdf
  Раздел 6, стр.18: стабильная contextual organization. Поисковая версия доступна; прямой PDF не выдал файл.

## Собственные источники

- 01_Visual_Artbook.pdf, стр.2–6,10–12; 02_Production_Atlas.pdf, H01/U01–U04.
- Asset_Production_Register.xlsx и data/assets.json: H01 dims6×1.25×4; cap4500tri; texture1024.
- assets/references/needle-quay-approved-style-board.png; SHA-256 сохранён в соседнем JSON.
- src/shared/Theme.luau, Pattern.luau, BeatBook.luau; src/client/WorkshopView.luau.
- docs/MILESTONE_VERIFICATION.md: существующая implementation evidence на 6ed1b00.
- Alpha01 tracker: https://github.com/slafftrosheen/BeatMakka/issues/1

## Генерация иллюстраций

Использован встроенный image_gen. Промпты и пути исходных результатов - в image-prompts.json. Никакие manufacturer screenshots/logos не включены. Первый неверный12-pad render не использован. Не изменены gameplay sources, asset IDs, реестр и asset acceptance stages.
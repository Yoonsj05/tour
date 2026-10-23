
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>지역별 여행지 카드북</title>

  <style>
    * {
      box-sizing: border-box;
    }

    body {
      font-family: Arial, sans-serif;
      background: #f1f6fa;
      margin: 0;
      color: #243746;
    }

    header {
      background: #1976a3;
      color: white;
      padding: 35px 20px;
      text-align: center;
    }

    header h1 {
      margin: 0 0 12px;
    }

    main {
      max-width: 1100px;
      margin: 30px auto;
      padding: 0 20px;
    }

    .search-box {
      background: white;
      padding: 25px;
      border-radius: 12px;
      box-shadow: 0 3px 12px #00000012;
    }

    select {
      width: 100%;
      padding: 13px;
      margin-top: 12px;
      border: 1px solid #cccccc;
      border-radius: 8px;
      font-size: 16px;
    }

    #status {
      margin: 20px 0;
      color: #555555;
    }

    #cards {
      display: grid;
      grid-template-columns:
        repeat(auto-fit, minmax(230px, 1fr));
      gap: 20px;
      margin-top: 20px;
    }

    .card {
      background: white;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 3px 12px #00000012;
    }

    .card img {
      width: 100%;
      height: 180px;
      object-fit: cover;
    }

    .card-content {
      padding: 15px;
    }

    .card h3 {
      margin-top: 0;
    }

    .card p {
      color: #666666;
      font-size: 14px;
    }

    #resultSection[hidden] {
      display: none;
    }
  </style>
</head>

<body>

  <header>
    <h1>지역별 여행지 카드북</h1>
    <p>대한민국의 아름다운 여행지를 찾아보세요!</p>
  </header>

  <main>

    <div class="search-box">
      <h2>여행 지역 선택</h2>

      <select id="regionSelect">
        <option value="">지역을 선택하세요</option>
        <option value="11">서울</option>
        <option value="26">부산</option>
        <option value="27">대구</option>
        <option value="28">인천</option>
        <option value="29">광주</option>
        <option value="30">대전</option>
        <option value="31">울산</option>
        <option value="36">세종</option>
        <option value="41">경기</option>
        <option value="51">강원</option>
        <option value="43">충북</option>
        <option value="44">충남</option>
        <option value="52">전북</option>
        <option value="46">전남</option>
        <option value="47">경북</option>
        <option value="48">경남</option>
        <option value="50">제주</option>
      </select>
    </div>

    <p id="status">저장된 지역 정보를 확인하는 중...</p>

    <section id="resultSection" hidden>
      <h2 id="regionTitle"></h2>
      <div id="cards"></div>
    </section>

  </main>

  <script type="module">

    import { initializeApp }
      from "https://www.gstatic.com/firebasejs/13.0.0/firebase-app.js";

    import { getFirestore, doc, getDoc }
      from "https://www.gstatic.com/firebasejs/13.0.0/firebase-firestore.js";


    // 1. Firebase 콘솔에서 복사한 설정으로 교체
    const firebaseConfig = {
      apiKey: "여기에_API_KEY",
      authDomain: "여기에_AUTH_DOMAIN",
      projectId: "여기에_PROJECT_ID",
      storageBucket: "여기에_STORAGE_BUCKET",
      messagingSenderId: "여기에_SENDER_ID",
      appId: "여기에_APP_ID"
    };


    // 2. 나중에 Node.js 서버 배포 후 URL 교체
    const FUNCTION_URL =
      "https://asia-northeast3-YOUR_PROJECT_ID.cloudfunctions.net/travelApi";


    const app = initializeApp(firebaseConfig);
    const db = getFirestore(app);

    const regionSelect =
      document.getElementById("regionSelect");

    const status =
      document.getElementById("status");

    const resultSection =
      document.getElementById("resultSection");

    const regionTitle =
      document.getElementById("regionTitle");

    const cards =
      document.getElementById("cards");


    // 관광정보 카드 생성
    function showCards(data) {

      if (!data) {
        resultSection.hidden = true;
        status.textContent =
          "저장된 지역이 없어요. 지역을 선택해 주세요.";
        return;
      }

      regionSelect.value = data.regionCode;
      regionTitle.textContent =
        data.regionName + " 관광지";

      cards.replaceChildren();

      const items = data.items || [];

      items.forEach(item => {

        const card = document.createElement("div");
        card.className = "card";

        const image = document.createElement("img");
        image.src = item.image;
        image.alt = item.title;

        const content = document.createElement("div");
        content.className = "card-content";

        const title = document.createElement("h3");
        title.textContent = item.title;

        const address = document.createElement("p");
        address.textContent = item.address;

        content.append(title, address);
        card.append(image, content);
        cards.append(card);

      });

      resultSection.hidden = false;

      status.textContent =
        data.regionName + " 관광정보 " +
        items.length + "개를 표시했어요.";
    }


    // 처음 접속했을 때 Firestore 정보 불러오기
    async function loadSavedData() {

      try {

        const reference =
          doc(db, "travelCardbook", "latest");

        const snapshot = await getDoc(reference);

        if (snapshot.exists()) {
          showCards(snapshot.data());
        } else {
          showCards(null);
        }

      } catch (error) {
        console.error(error);
        status.textContent =
          "Firebase 연결 오류: " + error.message;
      }

    }


    // 지역 선택 시 Node.js 서버 호출
    regionSelect.addEventListener(
      "change",
      async function () {

        const regionCode = regionSelect.value;

        if (!regionCode) return;

        status.textContent =
          "관광정보를 불러오는 중...";

        regionSelect.disabled = true;

        try {

          const url =
            FUNCTION_URL +
            "?regionCode=" +
            encodeURIComponent(regionCode);

          const response = await fetch(url);

          const result = await response.json();

          if (!response.ok) {
            throw new Error(
              result.error || "관광정보 조회 실패"
            );
          }

          showCards(result.saved);

        } catch (error) {

          console.error(error);

          status.textContent =
            "오류: " + error.message;

        } finally {
          regionSelect.disabled = false;
        }

      }
    );


    loadSavedData();

  </script>

</body>
</html>

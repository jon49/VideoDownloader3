// @ts-ignore
(function () {
    document.addEventListener("click", function (e) {
        var _a;
        var $button;
        if (($button = e.target) instanceof HTMLButtonElement && $button.dataset.action === "remove") {
            e.preventDefault();
            var $urls = Array.from(document.getElementById("videos").querySelectorAll("[name=urls]"));
            if ($urls.length > 1) {
                var numberOfEmpties = $urls.reduce(function (acc, val) { return val.value.length === 0 ? acc + 1 : acc; }, 0);
                var $root = $button.closest("[data-root]");
                if (!(((_a = $root === null || $root === void 0 ? void 0 : $root.querySelector("input")) === null || _a === void 0 ? void 0 : _a.value.length) === 0 && numberOfEmpties === 1))
                    $root === null || $root === void 0 ? void 0 : $root.remove();
            }
        }
    });
    document.addEventListener("change", function (e) {
        var _a, _b;
        var input;
        const $form = document.getElementById("videos")
        if ((input = e.target) instanceof HTMLInputElement
            && input.name === "urls") {
            if (input.value.length > 0) {
                var parent_1 = input.parentElement;
                if (!parent_1)
                    return;
                var urls = Array.from($form.querySelectorAll("[name=urls]"));
                if (!urls.find(function (x) { return x.value.length === 0; })) {
                    var $url = parent_1.cloneNode(true);
                    if ($url) {
                        var $input = $url.querySelector("input");
                        if ($input)
                            $input.value = "";
                        (_a = document.getElementById("urls")) === null || _a === void 0 ? void 0 : _a.append($url);
                    }
                }
                var url = input.value;
                fetch("/videos?url=" + encodeURI(url))
                    .then(function (x) { return x.json(); })
                    .then(function (x) {
                    if (input.value.length) {
                        var $span = parent_1.querySelector("[data-video-name]");
                        if ($span) {
                            $span.textContent = x.name;
                            $span.setAttribute("title", x.name);
                        }
                    }
                }).catch(function (x) {
                    console.error(x);
                    var template = document.getElementById("error");
                    if (!template)
                        return;
                    var $error = template.content.cloneNode(true);
                    $error.textContent = x;
                    var $errors = document.getElementById("errors");
                    if ($errors) {
                        $errors.innerHTML = "";
                        $errors.appendChild($error);
                    }
                });
            }
            else {
                var videoName = (_b = input === null || input === void 0 ? void 0 : input.parentElement) === null || _b === void 0 ? void 0 : _b.querySelector("[data-video-name]");
                if (videoName)
                    videoName.textContent = "";
            }
        }
    });
}());

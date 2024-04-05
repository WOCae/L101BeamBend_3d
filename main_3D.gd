extends Control

#入力用のライン設定
var line_edit_L: LineEdit
var line_edit_b: LineEdit
var line_edit_h: LineEdit
var line_edit_P: LineEdit
var line_edit_E: LineEdit
var line_edit_dx: LineEdit
var line_edit_σ: LineEdit

#実行用ボタン
var Button_edit: Button

#出力用のテキスト欄
var Text_edit: TextEdit

func _ready():
	#シーンノードセット
	line_edit_L = $LineEdit_L
	line_edit_b = $LineEdit_b
	line_edit_h = $LineEdit_h
	line_edit_P = $LineEdit_P
	line_edit_E = $LineEdit_E	
	line_edit_dx = $LineEdit_dx
	line_edit_σ = $LineEdit_σ	
	#line_edit_dx.set_editable(false) #グレーアウトして触れなくできる
	Text_edit = $TextEdit
	
	Button_edit = $Button

#-----------------------------------
#変数
var L:float
var b:float
var h:float
var P:float
var E:float

var I:float
var y:float
var Z:float
var M:float

var dx:float
var σ:float

#calc実行
func _on_button_pressed():
	#入力値
	L = float(line_edit_L.text)
	b = float(line_edit_b.text)
	h = float(line_edit_h.text)
	P = float(line_edit_P.text)
	E = float(line_edit_E.text)
	
	#計算
	I = b*h**3/12
	dx = P*L**3/3/E/I

	y = h/2
	Z = I/y
	M = P*L
	σ = M/Z

	#結果表示
	$Label_dx_output.text = str("%8.3f" % dx).replace(" ","")
	$Label_σ_output.text = str("%8.2f" % σ).replace(" ","")

	Text_edit.text = (
	"I:"+
	str("%8.3f" % I)
	+"\n"+
	"Z:"+
	str("%8.2f" % Z)
	+"\n"+
	"dx:"+
	str("%8.3f" % dx)
	+"\n"+
	"σ:"+
	str("%8.3f" % σ)
	)
	
	#上部形状について
	#--------ラインの位置変更------------------------------------
	var base_L:float = 100
	var base_b:float = 10
	var base_h:float = 10
	var coefficient_L:float
	var coefficient_b:float
	var coefficient_h:float
	
	coefficient_L = L/base_L
	coefficient_b = b/base_b
	coefficient_h = h/base_h
	
	var my_array = [1, 2, 3, 4, 5]
	var max_value = my_array[0]


	var coefArry = [coefficient_L,coefficient_b,coefficient_h]
	var maxCoef:float
	for i in range(0, coefArry.size()):
		if coefArry[i] > maxCoef:
			maxCoef = coefArry[i]
	#print(maxCoef)

	var minCoef:float = 10000
	for i in range(0, coefArry.size()):
		if coefArry[i] < minCoef:
			minCoef = coefArry[i]
	#print(minCoef)
	var coef:float
	coef = maxCoef/1
	#print(coef)
	#正面
	$Line2D.set_point_position(0, Vector2(0, 0))		
	$Line2D.set_point_position(1, Vector2(L, 0))
	$Line2D.set_point_position(2, Vector2(L, h))
	$Line2D.set_point_position(3, Vector2(0, h))
	#断面形状
	$Line2D2.set_point_position(0, Vector2(0, 0))	
	$Line2D2.set_point_position(1, Vector2(b, 0))
	$Line2D2.set_point_position(2, Vector2(b, h))
	$Line2D2.set_point_position(3, Vector2(0, h))
	
	#描画スケール
	$Line2D.scale = Vector2(3/coef,3/coef)
	$Line2D2.scale = Vector2(3/coef,3/coef)	
	
	$Line2D.width = 1*coef
	$Line2D2.width = 1*coef

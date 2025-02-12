import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;


  Future<String> extractData(currency) async
  {
    final response = await http.Client().get(Uri.parse('https://www.x-rates.com/table/?from=USD&amount=1'));
    if(response.statusCode == 200)
    {
      var document = parser.parse(response.body);
      var data = document.getElementsByClassName('tablesorter ratesTable')[0].children[1];
      for(int i = 0;;i++)
      {
        try
        {
          var conversion = data.children[i].text.trim().split('\n');
          if(currency == conversion[0])
          {
            return conversion[1];
          }

        }
        catch(e)
        {
          return 'Error';
        }
        



      }



    }
    else{
     return "Error" ;
    }
   

  }


Future convert(currency1, currency2, amount)
async {
  var convert1 = await extractData(currency1);
  var convert2 = await extractData(currency2);

  if(convert1 != "Error" && convert2 != "Error")
  {
    double conversion_rate = double.parse(convert1) / double.parse(convert2);
    return amount/conversion_rate ;
  }
  else
  {
    return -1.0;
  }



}



<script>
{assign var="epgroup_field" value="group"}
{assign var="return_party" value="organization_name,nick_name,legal_name,country,$epgroup_field"}

var epgroup_field = "{$epgroup_field}";
var countries_flat = {crmAPI sequential=0 entity="Constant" name="country"}.values;
var countries = {crmAPI entity="Country"}.values;

var country_field = "custom_3";
var party_field = "custom_5";

var parties = {crmAPI entity="Contact" contact_sub_type="party" option_limit=1000 return="organization_name,country" option_sort="organization_name ASC"}.values;

var candidates = {crmAPI entity="Candidate" option_limit=1000 }.values;
{literal}
var parties_flat = {}; 

cj(function($) {
    countries_flat["_"]="-select-";

    $.each(countries_flat, function (n) {
      parties_flat[n]= {};
    });
    $.each(parties, function(n) {
        parties_flat[parties[n].country_id][parties[n].id]=parties[n].organization_name;
    });

    $.each(candidates, function(n) {
      if (candidates[n].party) {
        if (parties_flat[candidates[n].country][candidates[n].party]) { 
          candidates[n].party=parties_flat[candidates[n].country][candidates[n].party];
        } else {
          candidates[n].party="<b>party "+candidates[n].party+" missing</b>";
        }
      } else {
        candidates[n].party="";
      };
      if (candidates[n].country) {
        candidates[n].country = countries_flat[candidates[n].country];
      }
    });

// Set the classes that TableTools uses to something suitable for Bootstrap
$.extend( true, $.fn.DataTable.TableTools.classes, {
  "container": "btn-group",
  "buttons": {
    "normal": "btn",
    "disabled": "btn disabled"
  },
  "collection": {
    "container": "DTTT_dropdown dropdown-menu",
    "buttons": {
      "normal": "",
      "disabled": "disabled"
    }
  }
} );

// Have the collection use a bootstrap compatible dropdown
$.extend( true, $.fn.DataTable.TableTools.DEFAULTS.oTags, {
  "collection": {
    "container": "ul",
    "button": "li",
    "liner": "a"
  }
} );
    var oTable = $('#contacts').dataTable( {
    "sDom": "<'row-fluid'<'span6'T><'span6'f>r>t<'row-fluid'<'span6'i><'span6'p>>",
    "oTableTools": {
      "sSwfPath": "/extensions/ep2014/TableTools/swf/copy_csv_xls.swf",
    },
    bJQueryUI: true,
    "bStateSave": true,
    "bPaginate":false,
    "aaData": candidates,
    "aoColumns": [
        //{ "sTitle": "party" , mDataProp:"party","sClass": "party"},
//           { "sTitle": "id",mData:"id"},
        { "sTitle": "First Name", mDataProp: "first_name",sClass: "editable"},
        { "sTitle": "Last Name", mDataProp: "last_name",sClass: "editable"},
        { "sTitle": "country", mDataProp:"country", "sClass": "country" },
        { "sTitle": "party", mDataProp:"party", "sClass": "party" },
        { "sTitle": "email" , mDataProp:"email","sClass": "editable"},
        { "sTitle": "website" , mDataProp:"website","sClass": "editable"},
        { "sTitle": "facebook" , mDataProp:"facebook","sClass": "editable"},
        { "sTitle": "twitter" , mDataProp:"twitter","sClass": "editable"},
    ],
    "fnDrawCallback": function () {
//TODO: add the editable
    }
  });

   var editableSettings = { 
     callBack:function(data){
          if (data.is_error) {
            editableSettings.error.call (this,data);
          } else {
             return editableSettings.success.call (this,data);
          }
        },
        error: function(data) {
          $(this).crmError(data.error_message, ts('Error'));
          $(this).removeClass('crm-editable-saving');
        },
        success: function(entity,field,value) {
          var $i = $(this);
          CRM.alert(value, ts('Saved'), 'success');
          $i.removeClass ('crm-editable-saving crm-error');
          $i.html(value);
        }
   };

    /* Apply the jEditable handlers to the table */
    var settings =  {
        "callback": function( sValue, y ) {
            var aPos = oTable.fnGetPosition( this );
            oTable.fnUpdate( sValue, aPos[0], aPos[1] );
        },
          data: function(value, settings) {
              return value.replace(/<(?:.|\n)*?>/gm, '');
            },
  
        "height": "24px",
        "width": "100%",
        "placeholder": '<span class="crm-editable-placeholder">Click to edit</span>',
        "onblur": "ignore" 
    };

    oTable.$('td.editable').editable( function(value,settings) {
      $(this).addClass ('crm-editable-saving');
      pos = oTable.fnGetPosition( this );
      row= pos[0];
      column= pos[2];
      contact_id=candidates[row].id;
      field = oTable.fnSettings().aoColumns[column].mData;
      CRM.api("candidate", "setvalue", {"field":field,"value":value, "id":contact_id}, {
        context: this,
        error: function (data) {
          editableSettings.error.call(this,data);
        },
        success: function (data) {
          CRM.alert( ts('Saved') + " " + value,candidates[row].last_name, 'success');
        }
      });
      return value;
    },settings);

    /* Apply the jEditable handlers to the parties */
    settings.type="select";
    settings.data=function (value,settings) {
      var pos = oTable.fnGetPosition( this );
      var row= pos[0];
      var country_id= candidates[row].country;
      if (isNaN (parseInt(country_id))) {
        country_id= Object.keys(countries_flat).filter(function(key) {return countries_flat[key] === country_id})[0];
      }
      return parties_flat[country_id];
    } 
    settings.onblur = 'submit';
 
    oTable.$('td.party').editable( function(value,settings) {
      $(this).addClass ('crm-editable-saving');
      pos = oTable.fnGetPosition( this );
      row= pos[0];
      column= pos[2];
      entity="Contact";
      var country_id= candidates[row].country;
      if (isNaN (parseInt(country_id))) {
        country_id= Object.keys(countries_flat).filter(function(key) {return countries_flat[key] === country_id})[0];
      }
      var params = {};
      params["id"]=candidates[row].id; 
      params[party_field]=value; 
      CRM.api(entity, "create", params, {
        context: this,
        error: function (data) {
          editableSettings.error.call(this,data);
        },
        success: function (data) {
          CRM.alert( candidates[row].last_name , ts('Saved') + " " + parties_flat[country_id][value], 'success');
        }
      });
      return parties_flat[country_id][value];
    },settings);

    /* Apply the jEditable handlers to the countries */
    settings.data=countries_flat;
    oTable.$('td.country').editable( function(value,settings) {
      $(this).addClass ('crm-editable-saving');
      pos = oTable.fnGetPosition( this );
      row= pos[0];
      column= pos[2];
      entity="Contact";
      contact_id=candidates[row].id;
      var param = {"id": candidates[row].id};
      param[country_field]=value;
      CRM.api(entity, "create", param, {
        context: this,
        error: function (data) {
          editableSettings.error.call(this,data);
        },
        success: function (data) {
          candidates[row].country = value;
          CRM.alert(candidates[row].last_name ,countries_flat[value] +" "+ ts('Saved'), 'success');
        }
      });
      return countries_flat[value];
    },settings);

    $(".ui-widget-header").append("<button id='add' class='add_row'>Add</button>");
    var o= "";
    $.each(countries, function (i,d) {
      o = o + "<option value='"+d.id+"'>"+d.name+"</option>";
    });
    $("#new_dialog select#country").append (o);
    
    var o= "<option value=''>-select-</option>";
    $.each(parties, function (i,d) {
      o = o + "<option value='"+d.id+"'>"+d.organization_name+"</option>";
    });
    $("#new_dialog select#"+epgroup_field).append (o);
    $("#new_dialog").dialog({"modal":true, autoOpen:false}).submit (function (e) {
      e.preventDefault();
      var fields = ["organization_name", "legal_name", "nick_name", "country",epgroup_field];
      var params = {
        "dedupe_check":true,
        "source": "civicrm/candidate",
        "sequential": 1,
        "contact_type":"Individual",
        "contact_sub_type":"candidate"
      };
      $.each(fields, function(id) {
        params[fields[id]]=$("#"+fields[id]).val();
      });
      params["api.address"]={"location_type_id":2,"is_primary":1,"country_id":params["country"]};
      var entity="contact";
      CRM.api(entity, "create", params, {
        context: this,
        error: function (data) {
          CRM.alert(data.error_message, 'Save error', 'error')
          console.log (data);
        },
        success: function (data) {
          params["id"]=data["id"];
          params[epgroup_field]=groups_flat[params[epgroup_field]];
          params["country"]=countries_flat[params["country"]];
          oTable.fnAddData( params);
          $("#new_dialog").dialog('close');
          CRM.alert(params.organization_name, 'Saved', 'success')
        }
      });
    });
      
    $("#add").click(function () { $("#new_dialog").dialog('open'); });

    $('#contacts select').live('change', function () {
      $(this).closest("form").submit();
//      alert("Change Event Triggered On:" + $(this).attr("value"));
    });

});

</script>
<style>
  td {word-break:break-word}
</style>
{/literal}

<table id="contacts"></table>

<div id="new_dialog">
<form>
<div class="form-item">
<label>First Name</label>
<input id="first_name"  class="form-control "/>
<label>Last Name</label>
<input id="last_name"  class="form-control "/>
<label>Email</label>
<input id="email"  class="form-control "/>
</div>
<div class="form-item">
<label>Country</label>
<select id="{$country_field}"  class="form-control ">
</select>
<label>Party</label>
<select id="{$party_field}"  class="form-control ">
</select>
</div>
<div class="form-item">
<label>Website</label>
<input id="website" class="form-control "/>
</div>
<div class="form-item">
<label>Facebook</label>
<input id="facebook"  class="form-control "/>
</div>
<div class="form-item">
<label>Twitter</label>
<input id="twitter"  class="form-control "/>
</div>

<input type="submit" name="save" class="btn-primary form-submit"/>
</form>
</div>

from flask import Flask,render_template,request,redirect,url_for,session
from pathlib import Path
import sys,os
sys.path.insert(0,str(Path(__file__).resolve().parent.parent/"shared"))
from database import connect,init_db
app=Flask(__name__);app.secret_key=os.getenv("CAFE_ADMIN_SECRET_KEY","change-admin-secret")
USER=os.getenv("CAFE_ADMIN_USERNAME","admin");PASS=os.getenv("CAFE_ADMIN_PASSWORD","Cafe@123")
@app.context_processor
def globals():return {"cafe_name":"THE DAILY BREW"}
@app.route("/login",methods=["GET","POST"])
def login():
 if session.get("admin"):return redirect(url_for("dashboard"))
 if request.method=="POST":
  if request.form.get("username")==USER and request.form.get("password")==PASS:session["admin"]=True;return redirect(url_for("dashboard"))
  return render_template("login.html",error="Incorrect username or password.")
 return render_template("login.html",error="")
@app.route("/logout")
def logout():session.clear();return redirect(url_for("login"))
@app.route("/")
def dashboard():
 if not session.get("admin"):return redirect(url_for("login"))
 status=request.args.get("status","All")
 if status not in ("All","Pending","Delivered"):status="All"
 with connect() as c:
  counts={"total":c.execute("SELECT COUNT(*) FROM orders").fetchone()[0],"pending":c.execute("SELECT COUNT(*) FROM orders WHERE status='Pending'").fetchone()[0],"delivered":c.execute("SELECT COUNT(*) FROM orders WHERE status='Delivered'").fetchone()[0]}
  orders=c.execute("SELECT * FROM orders"+("" if status=="All" else " WHERE status=?")+" ORDER BY id DESC",() if status=="All" else (status,)).fetchall()
 return render_template("dashboard.html",counts=counts,orders=orders,current_filter=status)
@app.post("/deliver/<int:oid>")
def deliver(oid):
 if not session.get("admin"):return redirect(url_for("login"))
 with connect() as c:c.execute("UPDATE orders SET status='Delivered' WHERE id=?",(oid,))
 return redirect(url_for("dashboard",status=request.form.get("status_filter","All")))
if __name__=="__main__":init_db();app.run(host="0.0.0.0",port=5001,debug=False)

library(ggplot2)
library(data.table)

wd <- "/opt/sharefolder/05.BGIAU-Bioinformatics/Tracking_Sequencer/HTML_PDF_Report/External/All_Machines"
plot_out_dir <- wd

xlsname <- paste0(wd,"/DataSource.xls")
pdf(file=paste0(wd,"/TrackingSequencer.pdf"), width = 10, height=6)

mydata <- read.csv(xlsname,sep="\t", header=T)  
mydata$Date <- as.POSIXct(as.POSIXlt(as.Date(mydata$Date) ,format="%Y-%M-%D",tz = "GMT"))

z0  <- subset(mydata,select=c("Date","Q30","Machine","estError"))
z0[z0==0]<-NA
mindate<-as.POSIXct("2017-07-10")
maxdate<-max(mydata$Date)
  
#### create plots
ggplot(z0[!is.na(z0$Q30),],aes(x=Date,y=Q30,color=Machine,group=Machine)) + 
  geom_line(na.rm=TRUE) +
  scale_x_datetime(expand=c(0,0),
                   date_breaks= "30 days", 
                   date_labels = "%m/%y", 
                   limits = as.POSIXct(c(mindate, maxdate))) +
  ylim(0, 100) +
  theme_bw() +
  scale_color_manual(values=c("#F8766D", "#B79F00", "#00BA38","#00BFC4","#619CFF","#F564E3")) +
  ggtitle("Q30's Distribution(%)") +
  theme(axis.title = element_text(size=14,face="bold"), axis.text = element_text(size=10)) 

ggplot(z0[!is.na(z0$estError),],aes(x=Date,y=estError,color=Machine,group=Machine)) + 
  geom_line(na.rm=TRUE) +
  scale_x_datetime(expand=c(0,0),
                   date_breaks= "30 days", 
                   date_labels = "%m/%y", 
                   limits = as.POSIXct(c(mindate, maxdate))) +
  ylim(0, 10) +
  theme_bw() +
  scale_color_manual(values=c("#F8766D", "#B79F00", "#00BA38","#00BFC4","#619CFF","#F564E3")) +
  ggtitle("Estimated Error's Distribution(%)") +
  theme(axis.title = element_text(size=14,face="bold"), axis.text = element_text(size=10)) 

## Accumulate Data

adx=c(as.POSIXct("2017-08-15",tz = "GMT"),as.POSIXct("2017-11-08",tz = "GMT"),as.POSIXct("2018-02-08",tz = "GMT"),as.POSIXct("2018-08-26",tz = "GMT"),as.POSIXct("2019-02-06",tz = "GMT"))
ady=c(100,500,5000,18500,38500)

labMv<-as.POSIXct("2018-04-10",tz = "GMT")
labMvY=7500
labMvend<-as.POSIXct("2018-07-08",tz = "GMT")
labMvendY=11800

z1 <- subset(mydata,select=c("Date","BaseNum","Machine"))
SUM<- sum(z1$BaseNum)/1000
mID <- unique(na.omit(z1$Machine))
zall=list()
for (i in 1:length(mID)) {
  z<-z1[which(z1$Machine == mID[i]),]
  z$CumulativeData <- setDT(z)[, cumsum(BaseNum)]
  zall<-rbind(zall,z,fill=TRUE)
}

z1$CumulativeData <- setDT(z1)[, cumsum(BaseNum)]
z1$Machine='All'

zall<-rbind(zall,z1,fill=TRUE)

ggplot(zall[!is.na(zall$CumulativeData),],aes(x=Date,y=CumulativeData,color=Machine,group=Machine)) + 
  geom_line(na.rm=TRUE) +
  scale_x_datetime(expand=c(0,0),
                   date_breaks= "60 days", 
                   date_labels = "%b %y", 
                   limits = as.POSIXct(c(mindate, maxdate))) +
  annotate("rect", xmin = labMv, xmax = labMvend, ymin = labMvY, ymax = labMvendY, alpha = .2) +
  annotate("text", x = labMv, y = labMvY - 1000, hjust="left",label = "Lab move and renovation",size=2.5) +
  
  annotate("segment", x = adx[1], xend = adx[1], y = ady[1], yend = ady[1] + 3000, colour = "black") +
  annotate("segment", x = adx[1], xend = adx[1], y = ady[1] + 3000, yend = ady[1], colour = "black", arrow=arrow(length = unit(0.2,"cm"))) +
  annotate("text", x = adx[1], y = ady[1] + 4000, label = "Zebra01") +
  
  annotate("segment", x = adx[2], xend = adx[2], y = ady[2], yend = ady[2] + 3000, colour = "black") +
  annotate("segment", x = adx[2], xend = adx[2], y = ady[2] + 3000, yend = ady[2], colour = "black", arrow=arrow(length = unit(0.2,"cm"))) +
  annotate("text", x = adx[2], y = ady[2] + 4000, label = "Zebra02") +
  
  annotate("segment", x = adx[3], xend = adx[3], y = ady[3], yend = ady[3] + 3000, colour = "black") +
  annotate("segment", x = adx[3], xend = adx[3], y = ady[3] + 3000, yend = ady[3], colour = "black", arrow=arrow(length = unit(0.2,"cm"))) +
  annotate("text", x = adx[3], y = ady[3] + 4000, label = "Zebra03") +
  
  annotate("segment", x = adx[4], xend = adx[4], y = ady[4], yend = ady[4] + 3000, colour = "black") +
  annotate("segment", x = adx[4], xend = adx[4], y = ady[4] + 3000, yend = ady[4], colour = "black", arrow=arrow(length = unit(0.2,"cm"))) +
  annotate("text", x = adx[4], y = ady[4] + 4000, label = "Panda01") +
  
  annotate("segment", x = adx[5], xend = adx[5], y = ady[5], yend = ady[5] + 3000, colour = "black") +
  annotate("segment", x = adx[5], xend = adx[5], y = ady[5] + 3000, yend = ady[5], colour = "black", arrow=arrow(length = unit(0.2,"cm"))) +
  annotate("text", x = adx[5], y = ady[5] + 4000, label = "Panda02") +
  
  scale_color_manual(values=c("#F8766D", "#B79F00", "#00BA38","#00BFC4","#619CFF","#F564E3")) +
  theme_bw() +
  xlab("2017 - present") + ylab("Gbases Sequenced") +
  ggtitle(paste0("All Sequencers Output = ",round(SUM,2)," Tbases")) +
  theme(axis.title = element_text(size=14,face="bold"), axis.text = element_text(size=10)) 
